import { initialState, COURSE_LIST, SEMESTER_TERMS, STUDENT_ID, PRICE_PER_CREDIT } from "./portalData.js";
import { campusPosts } from "./campusPosts.js";
import { cleanPresentationCopy } from "./presentationCopy.js";

export const stamp = () => new Date().toLocaleString("vi-VN");
export const uid = prefix => `${prefix}-${crypto.randomUUID().slice(0, 8).toUpperCase()}`;
export const defaults = {
  campusPosts, eventFollows: [],
  faculties: [{ id: "CNTT", name: "Khoa Công nghệ thông tin" }, { id: "QTKD", name: "Khoa Quản trị kinh doanh" }, { id: "KHCB", name: "Khoa Khoa học cơ bản" }, { id: "NN", name: "Khoa Ngoại ngữ" }],
  majors: [{ id: "IT", name: "Công nghệ thông tin", facultyId: "CNTT" }, { id: "SE", name: "Công nghệ phần mềm", facultyId: "CNTT" }, { id: "BA", name: "Quản trị kinh doanh", facultyId: "QTKD" }],
  classes: [{ id: "CNTT24A", name: "CNTT24A", majorId: "SE" }, { id: "CNTT24B", name: "CNTT24B", majorId: "IT" }, { id: "QTKD24A", name: "QTKD24A", majorId: "BA" }],
  lecturers: [{ id: "GV012", name: "Trần Quốc Huy", facultyId: "CNTT", email: "huy@campus.edu.vn" }, { id: "GV013", name: "Nguyễn Hoài Nam", facultyId: "CNTT", email: "nam@campus.edu.vn" }, { id: "GV014", name: "Đỗ Thành Trung", facultyId: "QTKD", email: "trung@campus.edu.vn" }],
  courses: COURSE_LIST.map(course => ({ ...course, facultyId: ({ "Công nghệ thông tin": "CNTT", "Khoa học cơ bản": "KHCB", "Ngoại ngữ": "NN" })[course.faculty] || "CNTT" })),
  semesters: Object.entries(SEMESTER_TERMS).map(([id, dates]) => ({ id, name: `Học kỳ ${id}`, ...dates, registrationOpen: true })),
  fundReceipts: [], handovers: [], mailLog: [], semesterReports: [], issuedInvoices: [],
};

export function normalizeState(input) {
  const source = input?.presentationCopyVersion === 1 ? input : { ...cleanPresentationCopy(input), presentationCopyVersion: 1 };
  const state = { ...structuredClone(initialState), ...structuredClone(defaults), ...source };
  if (!state.enrollments) {
    const pairs = state.grades.map(grade => ({ studentId: grade.studentId, sectionId: grade.sectionId }));
    state.enrollments = [...new Map(pairs.map(item => [`${item.studentId}:${item.sectionId}`, item])).values()];
  }
  // Legacy student registration list remains compatible with existing screens.
  state.enrollments = state.enrollments.filter(item => item.studentId !== STUDENT_ID);
  state.enrollments.push(...[...new Set(state.enrollmentIds)].map(sectionId => ({ studentId: STUDENT_ID, sectionId })));
  const firstTerm = state.sections.find(section => state.enrollmentIds.includes(section.id))?.semester || "2026-1";
  state.payments = state.payments.map(payment => ({ ...payment, semester: payment.semester || firstTerm, invoiceId: payment.invoiceId || `INV-${payment.studentId}-${payment.semester || firstTerm}` }));
  if (!state.users.some(user => user.role === "affairs")) state.users.push({ id: "U-CTSV", name: "Nguyễn Thu Trang", login: "ctsv", role: "affairs", status: "ACTIVE" });
  state.students = state.students.map(student => ({ ...student, schoolEmail: student.schoolEmail || `${student.id.toLowerCase()}@student.campus.edu.vn`, emailStatus: student.emailStatus || "ACTIVE" }));
  return state;
}

export function roster(state, sectionId) {
  const ids = new Set(state.enrollments.filter(item => item.sectionId === sectionId).map(item => item.studentId));
  return state.students.filter(student => ids.has(student.id));
}

export function invoices(state) {
  const groups = new Map();
  for (const enrollment of state.enrollments) {
    const section = state.sections.find(item => item.id === enrollment.sectionId);
    if (!section) continue;
    const course = state.courses.find(item => item.id === section.courseId);
    const id = `INV-${enrollment.studentId}-${section.semester}`;
    if (!groups.has(id)) groups.set(id, { id, studentId: enrollment.studentId, semester: section.semester, items: [], total: 0 });
    const invoice = groups.get(id);
    const amount = (course?.credits || 0) * PRICE_PER_CREDIT;
    invoice.items.push({ section, course, amount }); invoice.total += amount;
  }
  for (const payment of state.payments) {
    if (!groups.has(payment.invoiceId)) groups.set(payment.invoiceId, { id: payment.invoiceId, studentId: payment.studentId, semester: payment.semester, items: [], total: 0 });
  }
  for (const issued of state.issuedInvoices || []) groups.set(issued.id, { ...issued, issued: true });
  return [...groups.values()].map(invoice => {
    const paid = state.payments.filter(payment => payment.invoiceId === invoice.id).reduce((sum, payment) => sum + payment.amount, 0);
    return { ...invoice, paid, balance: Math.max(0, invoice.total - paid), credit: Math.max(0, paid - invoice.total), status: paid >= invoice.total ? "PAID" : paid > 0 ? "PARTIAL" : "UNPAID" };
  });
}

export function recordPayment(state, invoiceId, amount) {
  const invoice = invoices(state).find(item => item.id === invoiceId);
  if (!invoice || !Number.isSafeInteger(amount) || amount <= 0 || amount > invoice.balance) throw new Error("Số tiền phải là số nguyên dương và không vượt công nợ hóa đơn.");
  const payment = { id: uid("PAY"), invoiceId, studentId: invoice.studentId, semester: invoice.semester, amount, date: stamp(), method: "Ghi nhận khoản nộp học phí", note: "Khoản nộp đã được ghi nhận" };
  const issuedInvoices = state.issuedInvoices.some(item => item.id === invoice.id) ? state.issuedInvoices : [...state.issuedInvoices, { ...invoice, issuedAt: stamp() }];
  return { ...state, issuedInvoices, payments: [...state.payments, payment] };
}

export function forwardApplication(state, applicationId, classId) {
  const application = state.applications.find(item => item.id === applicationId);
  const targetClass = state.classes.find(item => item.id === classId);
  if (!application || application.status !== "ACCEPTED" || !targetClass) throw new Error("Chọn hồ sơ đã được CTSV kiểm tra và lớp hành chính hợp lệ.");
  if (state.studentApprovals.some(item => item.applicationId === applicationId)) throw new Error("Hồ sơ đã được chuyển Nhà trường.");
  const major = state.majors.find(item => item.id === targetClass.majorId);
  if (major?.name !== application.major) throw new Error("Lớp hành chính phải thuộc ngành người nộp đăng ký.");
  const studentId = application.studentId || uid("SV");
  const request = { id: uid("STU-REQ"), applicationId, status: "PENDING", submittedAt: stamp(), student: { id: studentId, name: application.name, email: application.email, phone: application.phone, address: application.address, className: targetClass.name, classId, major: major.name, year: `K${new Date().getFullYear()}`, status: "STUDYING" } };
  return { ...state, studentApprovals: [...state.studentApprovals, request], applications: state.applications.map(item => item.id === applicationId ? { ...item, status: "SCHOOL_PENDING", history: [...item.history, { status: "SCHOOL_PENDING", at: stamp(), note: `CTSV chuyển hồ sơ, xếp lớp ${targetClass.name}.` }] } : item), mailLog: [{ id: uid("MAIL"), to: application.email, subject: "Hồ sơ đã chuyển Nhà trường", status: "SIMULATED", date: stamp() }, ...state.mailLog] };
}

export function approveStudent(state, requestId, approved, reason = "") {
  const request = state.studentApprovals.find(item => item.id === requestId);
  if (!request || request.status !== "PENDING") throw new Error("Hồ sơ không còn chờ duyệt.");
  if (!approved && !reason.trim()) throw new Error("Cần nhập lý do từ chối.");
  const existing = state.students.find(item => item.id === request.student.id);
  if (approved && existing && !request.applicationId) throw new Error("Mã sinh viên đã tồn tại.");
  const schoolEmail = `${request.student.id.toLowerCase()}@student.campus.edu.vn`;
  const status = approved ? "ENROLLED" : "SCHOOL_REJECTED";
  const student = { ...request.student, schoolEmail, emailStatus: "ACTIVE", applicationId: request.applicationId };
  return { ...state,
    students: approved ? existing ? state.students.map(item => item.id === student.id ? { ...item, ...student } : item) : [...state.students, student] : state.students,
    users: approved && !state.users.some(item => item.studentId === student.id || item.login === student.id.toLowerCase()) ? [...state.users, { id: uid("U"), studentId: student.id, name: student.name, login: student.id.toLowerCase(), email: schoolEmail, role: "student", status: "ACTIVE" }] : state.users,
    studentApprovals: state.studentApprovals.map(item => item.id === requestId ? { ...item, status: approved ? "APPROVED" : "REJECTED", reviewedAt: stamp(), reason } : item),
    applications: state.applications.map(item => item.id === request.applicationId ? { ...item, status, assignedStudentId: student.id, history: [...item.history, { status, at: stamp(), note: approved ? `Đã cấp mã ${student.id}, email ${schoolEmail}.` : reason }] } : item),
    mailLog: [{ id: uid("MAIL"), to: student.email, subject: approved ? `Hồ sơ được duyệt · ${schoolEmail}` : `Hồ sơ bị từ chối: ${reason}`, status: "SIMULATED", date: stamp() }, ...state.mailLog],
  };
}

export function allocateToFund(state, paymentId) {
  const payment = state.payments.find(item => item.id === paymentId);
  if (!payment || state.fundReceipts.some(item => item.paymentId === paymentId)) throw new Error("Khoản thu không tồn tại hoặc đã liên kết quỹ.");
  return { ...state, fundReceipts: [...state.fundReceipts, { id: uid("FUND"), paymentId, amount: payment.amount, date: stamp(), fund: "Quỹ CTSV" }] };
}

export function createHandover(state, receiptIds, recipient) {
  const ids = [...new Set(receiptIds)];
  const reserved = new Set(state.handovers.flatMap(item => item.receiptIds));
  const receipts = ids.map(id => state.fundReceipts.find(item => item.id === id));
  if (!recipient.trim() || !ids.length || receipts.some(item => !item || reserved.has(item.id))) throw new Error("Chọn khoản quỹ chưa bàn giao và nhập người nhận hợp lệ.");
  return { ...state, handovers: [...state.handovers, { id: uid("BG"), recipient: recipient.trim(), receiptIds: ids, amount: receipts.reduce((sum, item) => sum + item.amount, 0), date: stamp(), status: "PENDING" }] };
}

export function confirmHandover(state, id) {
  if (!state.handovers.some(item => item.id === id && item.status === "PENDING")) throw new Error("Biên bản không còn chờ xác nhận.");
  return { ...state, handovers: state.handovers.map(item => item.id === id ? { ...item, status: "CONFIRMED", confirmedAt: stamp() } : item) };
}
