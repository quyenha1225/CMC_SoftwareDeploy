export const POST_TYPES = ["Sự kiện", "Hội thảo", "Thông báo"];
export const campusPosts = [
  { id: "EVT-CAREER-2026", title: "Ngày hội kết nối doanh nghiệp & định hướng nghề nghiệp", category: "Sự kiện", summary: "Gặp gỡ nhà tuyển dụng, tìm hiểu cơ hội thực tập và chuẩn bị hành trang nghề nghiệp.", content: "Sinh viên gặp gỡ đại diện doanh nghiệp, tìm hiểu vị trí thực tập và tham gia tư vấn nghề nghiệp.\n\nChương trình gồm giao lưu cùng cựu sinh viên, hướng dẫn chuẩn bị CV và chia sẻ kỹ năng phỏng vấn. Sinh viên mang theo thẻ sinh viên khi tham dự.", startsAt: "2026-11-20T08:00", endsAt: "2026-11-20T11:30", venue: "Hội trường A", organizer: "Phòng Công tác sinh viên", status: "PUBLISHED", publishedAt: "2026-11-08T08:00" },
  { id: "EVT-AI-2026", title: "Hội thảo: Trí tuệ nhân tạo trong học tập và nghiên cứu", category: "Hội thảo", summary: "Trao đổi cách ứng dụng AI có trách nhiệm, phát triển tư duy nghiên cứu và kỹ năng học tập.", content: "Buổi hội thảo dành cho sinh viên quan tâm đến công nghệ và phương pháp học tập.\n\nNội dung: tổng quan về AI, ví dụ ứng dụng trong nghiên cứu, kiểm chứng thông tin và trao đổi cùng giảng viên.", startsAt: "2026-11-18T14:00", endsAt: "2026-11-18T16:00", venue: "Phòng hội thảo B201", organizer: "Khoa Công nghệ thông tin", status: "PUBLISHED", publishedAt: "2026-11-07T09:00" },
  { id: "NEWS-STUDENT-2026", title: "Thông báo sinh hoạt sinh viên đầu học kỳ", category: "Thông báo", summary: "Lịch gặp cố vấn học tập, trao đổi kế hoạch học kỳ và các hoạt động đồng hành cùng sinh viên.", content: "Sinh viên theo dõi lịch sinh hoạt của lớp và chuẩn bị các câu hỏi về kế hoạch học tập.\n\nNội dung bao gồm quy chế học vụ, hỗ trợ sinh viên và giới thiệu các câu lạc bộ. Thông tin cụ thể sẽ được đơn vị tổ chức cập nhật tại bài viết này.", startsAt: "2026-11-16T09:00", endsAt: "2026-11-16T10:30", venue: "Theo lớp hành chính", organizer: "Phòng Công tác sinh viên", status: "PUBLISHED", publishedAt: "2026-11-06T09:00" },
];
export const foldText = value => String(value || "").normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/đ/g, "d").replace(/Đ/g, "D").toLowerCase();
export function filterPosts(posts, { query = "", category = "ALL", publishedOnly = true } = {}) {
  const terms = foldText(query).split(/\s+/).filter(Boolean);
  return posts.filter(post => (!publishedOnly || post.status === "PUBLISHED") && (category === "ALL" || post.category === category) && terms.every(term => foldText(`${post.title} ${post.summary} ${post.content} ${post.venue} ${post.organizer} ${post.category}`).includes(term))).sort((a, b) => (b.publishedAt || "").localeCompare(a.publishedAt || ""));
}
export function savePost(posts, draft, status) {
  if (!draft.title?.trim() || !draft.summary?.trim() || !draft.content?.trim() || !draft.venue?.trim() || !draft.organizer?.trim() || !POST_TYPES.includes(draft.category)) throw new Error("Điền đầy đủ tiêu đề, mô tả, nội dung, địa điểm và đơn vị tổ chức.");
  if (!draft.startsAt || !draft.endsAt || draft.startsAt >= draft.endsAt) throw new Error("Thời gian kết thúc phải sau thời gian bắt đầu.");
  if (!["DRAFT", "PUBLISHED"].includes(status)) throw new Error("Trạng thái bài viết không hợp lệ.");
  const previous = posts.find(post => post.id === draft.id);
  const post = { ...draft, id: previous?.id || `EVT-${crypto.randomUUID().slice(0, 8).toUpperCase()}`, status, title: draft.title.trim(), updatedAt: new Date().toISOString(), publishedAt: status === "PUBLISHED" ? previous?.publishedAt || new Date().toISOString() : previous?.publishedAt || "" };
  return previous ? posts.map(item => item.id === post.id ? post : item) : [post, ...posts];
}
