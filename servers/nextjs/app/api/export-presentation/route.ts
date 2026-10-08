import { NextRequest, NextResponse } from "next/server";
import fs from "fs/promises";
import path from "path";

import {
  BundledPresentationExportFormat,
  bundledExportPackageAvailable,
  runBundledPresentationExport,
} from "@/lib/run-bundled-presentation-export";
import { authStatusForRequest } from "@/lib/server-auth-role";

function isValidFormat(value: unknown): value is BundledPresentationExportFormat {
  return value === "pdf" || value === "pptx";
}

async function readExportRequestBody(req: NextRequest): Promise<{
  format?: unknown;
  id?: unknown;
  title?: unknown;
}> {
  const rawBody = await req.text();
  if (!rawBody.trim()) {
    throw new Error("EMPTY_BODY");
  }

  const parsed = JSON.parse(rawBody) as unknown;
  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
    throw new Error("INVALID_BODY");
  }

  return parsed as { format?: unknown; id?: unknown; title?: unknown };
}

function getAppDataDirectory(): string {
  return (
    process.env.APP_DATA_DIRECTORY?.trim() ||
    path.resolve(process.cwd(), "..", "..", "app_data")
  );
}

function buildExportDownloadUrl(outPath: string): string {
  const appDataDirectory = getAppDataDirectory();
  const exportsDirectory = path.join(appDataDirectory, "exports");
  const relativePath = path.relative(exportsDirectory, outPath);
  if (
    !relativePath ||
    relativePath.startsWith("..") ||
    path.isAbsolute(relativePath)
  ) {
    throw new Error("Export finished outside the configured exports directory.");
  }

  return `/api/export-presentation/file?name=${encodeURIComponent(relativePath)}`;
}

async function moveExportIntoOwnerDirectory(
  outPath: string,
  userId: string | null
): Promise<string> {
  if (!userId) {
    return outPath;
  }

  const appDataDirectory = getAppDataDirectory();
  const rawExportsDir = path.join(appDataDirectory, "exports");
  await fs.mkdir(rawExportsDir, { recursive: true });
  const exportsDirectory = await fs.realpath(rawExportsDir);
  const sourcePath = await fs.realpath(outPath);
  const ownerDirectory = path.join(exportsDirectory, "users", userId);
  await fs.mkdir(ownerDirectory, { recursive: true });

  const sourceParent = path.dirname(sourcePath);
  if (sourceParent === ownerDirectory) {
    return sourcePath;
  }
  const relativeSource = path.relative(exportsDirectory, sourcePath);
  if (
    !relativeSource ||
    relativeSource.startsWith("..") ||
    path.isAbsolute(relativeSource) ||
    relativeSource.split(path.sep)[0] === "users"
  ) {
    throw new Error("Export finished outside the current user's export directory.");
  }

  const destination = path.join(ownerDirectory, path.basename(sourcePath));
  await fs.rename(sourcePath, destination);
  return destination;
}

type ExportCacheEntry = {
  outPath: string;
  updatedAt: string;
};

type ExportCacheStore = Record<string, Record<string, ExportCacheEntry>>;

function getCacheFilePath(): string {
  const appData = getAppDataDirectory();
  return path.join(appData, "exports", ".export_cache.json");
}

async function readExportCache(): Promise<ExportCacheStore> {
  try {
    const raw = await fs.readFile(getCacheFilePath(), "utf8");
    return JSON.parse(raw);
  } catch {
    return {};
  }
}

async function writeExportCache(cache: ExportCacheStore): Promise<void> {
  try {
    const cacheFile = getCacheFilePath();
    await fs.mkdir(path.dirname(cacheFile), { recursive: true });
    await fs.writeFile(cacheFile, JSON.stringify(cache, null, 2), "utf8");
  } catch (err) {
    console.warn("[export-cache] Failed to save cache:", err);
  }
}

async function fetchPresentationUpdatedAt(
  presentationId: string,
  cookieHeader?: string
): Promise<string | null> {
  try {
    const fastApiUrl = (
      process.env.FAST_API_INTERNAL_URL?.trim() ||
      process.env.NEXT_PUBLIC_FAST_API?.trim() ||
      "http://127.0.0.1:8000"
    ).replace(/\/+$/, "");
    const res = await fetch(`${fastApiUrl}/api/v1/ppt/presentation/${presentationId}`, {
      headers: cookieHeader ? { cookie: cookieHeader } : undefined,
      cache: "no-store",
    });
    if (!res.ok) return null;
    const json = await res.json();
    return json.updated_at || null;
  } catch {
    return null;
  }
}

export async function POST(req: NextRequest) {
  const auth = await authStatusForRequest(req);
  if (!auth.authenticated) {
    return NextResponse.json({ detail: "Unauthorized" }, { status: 401 });
  }

  let body: Awaited<ReturnType<typeof readExportRequestBody>>;
  try {
    body = await readExportRequestBody(req);
  } catch (error) {
    if (
      error instanceof SyntaxError ||
      (error instanceof Error &&
        (error.message === "EMPTY_BODY" || error.message === "INVALID_BODY"))
    ) {
      return NextResponse.json(
        { error: "Invalid export request JSON body" },
        { status: 400 }
      );
    }
    throw error;
  }

  const { format, id, title } = body;
  const cookieHeader = req.headers.get("cookie") ?? "";

  if (typeof id !== "string" || !id.trim()) {
    return NextResponse.json(
      { error: "Missing Presentation ID" },
      { status: 400 }
    );
  }

  if (!isValidFormat(format)) {
    return NextResponse.json(
      { error: "Invalid export format" },
      { status: 400 }
    );
  }

  const presentationId = id.trim();

  // Fast-path: Check if up-to-date exported file already exists
  const currentUpdatedAt = await fetchPresentationUpdatedAt(presentationId, cookieHeader);
  if (currentUpdatedAt) {
    const cache = await readExportCache();
    const cachedEntry = cache[presentationId]?.[format];
    if (cachedEntry && cachedEntry.updatedAt === currentUpdatedAt) {
      try {
        const stats = await fs.stat(cachedEntry.outPath);
        if (stats.isFile() && stats.size > 0) {
          console.info(`[export-presentation:${format}] Instant cache hit for ${presentationId}`);
          return NextResponse.json({
            success: true,
            path: buildExportDownloadUrl(cachedEntry.outPath),
            cached: true,
          });
        }
      } catch {
        // Cache file invalid or removed, proceed to regenerate
      }
    }
  }

  try {
    if (!(await bundledExportPackageAvailable())) {
      throw new Error(
        "presentation-export runtime is not available. Run scripts/sync-presentation-export.cjs to install it."
      );
    }

    const { path: unscopedOutPath } = await runBundledPresentationExport({
      format,
      presentationId,
      title: typeof title === "string" ? title : undefined,
      cookieHeader,
    });
    const outPath = await moveExportIntoOwnerDirectory(
      unscopedOutPath,
      auth.user_id
    );

    if (currentUpdatedAt) {
      const cache = await readExportCache();
      if (!cache[presentationId]) {
        cache[presentationId] = {};
      }
      cache[presentationId][format] = {
        outPath,
        updatedAt: currentUpdatedAt,
      };
      await writeExportCache(cache);
    }

    return NextResponse.json({
      success: true,
      path: buildExportDownloadUrl(outPath),
    });
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    console.error(`[export-presentation:${format}]`, message);
    return NextResponse.json(
      { error: message, success: false },
      { status: 500 }
    );
  }
}
