import asyncio
import logging
from collections.abc import AsyncGenerator, AsyncIterator, Awaitable, Callable

from fastapi import HTTPException

from models.sse_response import SSEErrorResponse


async def safe_sse_stream(
    stream: AsyncIterator[str],
    *,
    logger: logging.Logger,
    error_detail: str,
    on_error: Callable[[], Awaitable[None]] | None = None,
    error_metadata: Callable[[Exception], Awaitable[dict[str, object]]] | None = None,
    heartbeat_interval: float = 3.0,
) -> AsyncGenerator[str, None]:
    queue: asyncio.Queue[object] = asyncio.Queue()
    sentinel = object()

    async def producer():
        try:
            async for chunk in stream:
                await queue.put(chunk)
            await queue.put(sentinel)
        except (Exception, asyncio.CancelledError) as exc:
            await queue.put(exc)

    producer_task = asyncio.create_task(producer())
    try:
        while True:
            try:
                item = await asyncio.wait_for(queue.get(), timeout=heartbeat_interval)
            except asyncio.TimeoutError:
                yield ": ping\n\n"
                continue

            if item is sentinel:
                break
            if isinstance(item, asyncio.CancelledError):
                logger.info("SSE stream cancelled by client")
                return
            if isinstance(item, Exception):
                exc = item
                logger.exception("SSE stream failed after response started")
                if on_error:
                    try:
                        await on_error()
                    except Exception:
                        logger.exception("SSE stream error cleanup failed")
                detail = exc.detail if isinstance(exc, HTTPException) else error_detail
                metadata: dict[str, object] = {}
                if error_metadata:
                    try:
                        metadata = await error_metadata(exc)
                    except Exception:
                        logger.exception("SSE stream error metadata lookup failed")
                yield SSEErrorResponse(detail=str(detail), **metadata).to_string()
                break

            yield str(item)
    finally:
        if not producer_task.done():
            producer_task.cancel()
            try:
                await producer_task
            except (asyncio.CancelledError, Exception):
                pass
