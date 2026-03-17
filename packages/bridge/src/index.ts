import "dotenv/config";
import { startServer } from "./server";

startServer().catch((err) => {
  console.error(`[${new Date().toISOString()}] [Fatal] Failed to start server:`, err);
  process.exit(1);
});
