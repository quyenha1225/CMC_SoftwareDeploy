// Migrate legacy presentation copy without changing IDs or persistence keys.
const exact = new Map([
  ["Dữ liệu demo", "Thông tin học vụ"],
  ["Khoản thu giả lập", "Khoản nộp học phí"],
  ["Không có giao dịch thật", "Khoản nộp đã được ghi nhận"],
  ["Không chuyển tiền thật", "Khoản nộp đã được ghi nhận"],
]);
export function cleanPresentationCopy(value, key = "") {
  if (["id", "data", "password_hash", "passwordHash"].includes(key)) return value;
  if (typeof value === "string") return (exact.get(value) || value)
    .replace(/\s*\(demo\)/gi, "")
    .replace(/\.demo@/g, "@")
    .replace(/\n\nThông tin minh họa cho bản demo EduPortal\./g, "")
    .replace(/Ghi nhận thanh toán demo/gi, "Ghi nhận khoản nộp học phí")
    .replace(/thanh toán mô phỏng/gi, "khoản nộp học phí");
  if (Array.isArray(value)) return value.map(item => cleanPresentationCopy(item));
  if (value && typeof value === "object") return Object.fromEntries(Object.entries(value).map(([name, item]) => [name, cleanPresentationCopy(item, name)]));
  return value;
}
