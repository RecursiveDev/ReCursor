import type { Request, Response, NextFunction } from "express";
import { config } from "../config";

function extractBearerToken(req: Request): string | null {
  const auth = req.headers.authorization;
  if (!auth || !auth.startsWith("Bearer ")) {
    return null;
  }
  return auth.slice(7);
}

export function validateBridgeToken(req: Request, res: Response, next: NextFunction): void {
  const token = extractBearerToken(req);
  if (!token || token !== config.BRIDGE_TOKEN) {
    res.status(401).json({
      error: "Unauthorized",
      message: "Invalid or expired token",
      code: "AUTH_INVALID_TOKEN",
    });
    return;
  }
  next();
}

export function validateHookToken(req: Request, res: Response, next: NextFunction): void {
  const token = extractBearerToken(req);
  if (!token || token !== config.HOOK_TOKEN) {
    res.status(401).json({
      error: "Unauthorized",
      message: "Invalid hook token",
      code: "HOOK_AUTH_FAILED",
    });
    return;
  }
  next();
}
