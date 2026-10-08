import fs from "fs";
import fsPromises from "fs/promises";
import path from "path";
import { Readable } from "stream";
import { NextRequest, NextResponse } from "next/server";
import { authStatusForRequest } from "@/lib/server-auth-role";

const CONTENT_TYPES: Record<string, string> = {
  ".pdf": "application/pdf",
  ".pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation",
  ".zip": "application/zip",
};

function getExportsDirectory(): string {
  const appDataDirectory =
    process.env.APP_DATA_DIRECTORY?.trim() ||
    path.resolve(process.cwd(), "..", "..", "app_data");
  return path.join(appDataDirectory, "exports");
}

function getSafeExportName(
  request: NextRequest,
  userId: string | null,
  isAdmin: boolean,
): string | null {
  const rawName = request.nextUrl.searchParams.get("name");
  if (!rawName) {
    return null;
  }

  // Normalize forward and back slashes
  const unified = rawName.replace(/\\/g, "/").trim();
  if (!unified || unified.startsWith("/") || /^[a-zA-Z]:/.test(unified)) {
    return null;
  }

  const normalized = path.normalize(unified);
  if (
    normalized === ".." ||
    normalized.startsWith(`..${path.sep}`) ||
    normalized.startsWith("../") ||
    path.isAbsolute(normalized)
  ) {
    return null;
  }
  if (!userId) return normalized;

  const parts = normalized.split(path.sep).filter(Boolean);
  if (parts[0] === "users") {
    return parts.length >= 3 && parts[1] === userId ? normalized : null;
  }
  return isAdmin && parts.length === 1 ? normalized : null;
}

function contentDisposition(filename: string): string {
  const fallback = filename.replace(/[^a-zA-Z0-9._-]/g, "_");
  return `attachment; filename="${fallback}"; filename*=UTF-8''${encodeURIComponent(filename)}`;
}

export async function GET(request: NextRequest) {
  const auth = await authStatusForRequest(request);
  if (!auth.authenticated) {
    return NextResponse.json({ detail: "Unauthorized" }, { status: 401 });
  }
  const filename = getSafeExportName(
    request,
    auth.user_id,
    auth.role === "admin",
  );
  if (!filename) {
    return NextResponse.json({ error: "Invalid export file name" }, { status: 400 });
  }

  try {
    const exportsDirectory = getExportsDirectory();
    const resolvedExportsDirectory = await fsPromises.realpath(exportsDirectory);
    const filePath = path.join(exportsDirectory, filename);
    const resolvedFilePath = await fsPromises.realpath(filePath);

    if (
      resolvedFilePath !== resolvedExportsDirectory &&
      !resolvedFilePath.startsWith(resolvedExportsDirectory + path.sep)
    ) {
      return NextResponse.json({ error: "Access denied" }, { status: 403 });
    }

    const stats = await fsPromises.stat(resolvedFilePath);
    const stream = Readable.toWeb(fs.createReadStream(resolvedFilePath));
    return new NextResponse(stream as unknown as BodyInit, {
      headers: {
        "Content-Type": "application/octet-stream",
        "Content-Disposition": contentDisposition(path.basename(filename)),
        "Content-Length": String(stats.size),
        "Cache-Control": "no-store",
      },
    });
  } catch (error) {
    if ((error as NodeJS.ErrnoException)?.code === "ENOENT") {
      return NextResponse.json({ error: "Export file not found" }, { status: 404 });
    }

    console.error("[export-presentation:file]", error);
    return NextResponse.json(
      { error: "Failed to download export file" },
      { status: 500 }
    );
  }
}
