export const APPLICATION_STATUS = {
  SCHOOL_PENDING: "Chờ Nhà trường duyệt",
  ENROLLED: "Đã duyệt nhập học",
  SCHOOL_REJECTED: "Nhà trường từ chối",
  SUBMITTED: "Chờ tiếp nhận",
  RECEIVED: "Đã tiếp nhận",
  SUPPLEMENT: "Cần bổ sung",
  ACCEPTED: "Hoàn tất hồ sơ",
  REJECTED: "Từ chối",
};
export const DOCUMENT_TYPES = ["Giấy báo nhập học", "Giấy tờ tùy thân", "Bằng tốt nghiệp / giấy chứng nhận", "Học bạ"];
export const MAX_DOCUMENT_BYTES = 1024 * 1024;
export const MAX_TOTAL_BYTES = 2 * 1024 * 1024;
export const ALLOWED_TYPES = ["application/pdf", "image/jpeg", "image/png"];
export function canTransition(from, to) {
  return ({ SUBMITTED: ["RECEIVED"], RECEIVED: ["SUPPLEMENT", "ACCEPTED", "REJECTED"], SUPPLEMENT: ["SUBMITTED"] }[from] || []).includes(to);
}
