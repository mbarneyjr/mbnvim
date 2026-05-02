import { createCipheriv, randomBytes } from "node:crypto";

const key = Buffer.from(process.argv[2], "base64");
const plaintext = await new Promise((resolve) => {
  let data = "";
  process.stdin.on("data", (chunk) => (data += chunk));
  process.stdin.on("end", () => resolve(data));
});

const iv = randomBytes(12);
const protectedHeader = Buffer.from(
  JSON.stringify({ alg: "dir", enc: "A256GCM" })
);
const protectedHeaderB64 = base64url(protectedHeader);

const cipher = createCipheriv("aes-256-gcm", key, iv);
cipher.setAAD(Buffer.from(protectedHeaderB64, "ascii"));
const ciphertext = Buffer.concat([
  cipher.update(plaintext, "utf8"),
  cipher.final(),
]);
const tag = cipher.getAuthTag();

process.stdout.write(
  [protectedHeaderB64, "", base64url(iv), base64url(ciphertext), base64url(tag)].join(".")
);

function base64url(buf) {
  return buf.toString("base64").replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}
