import React from "react";
import Icon from "../common/Icon.jsx";
import "./RegulationsSection.css";

const regulations = [
  {
    title: "Chuyên cần và nghỉ học",
    icon: "calendar",
    warning: "Cần lưu ý",
    points: [
      "Theo dõi lịch học và yêu cầu chuyên cần trong đề cương từng học phần; không tự suy đoán số buổi nghỉ được phép.",
      "Khi cần nghỉ, chủ động báo giảng viên và Phòng Đào tạo theo kênh, thời hạn nhà trường quy định; lưu lại minh chứng hợp lệ nếu có.",
      "Nghỉ không phép hoặc vượt ngưỡng chuyên cần có thể ảnh hưởng điểm quá trình, điều kiện dự thi hoặc kết quả học phần theo quy chế áp dụng.",
      "Việc gửi đơn xin nghỉ không đồng nghĩa với việc đơn đã được chấp thuận.",
    ],
  },
  {
    title: "Thi cử và liêm chính học thuật",
    icon: "shield",
    warning: "Cảnh báo nghiêm túc",
    points: [
      "Không mang hoặc sử dụng tài liệu, điện thoại, đồng hồ thông minh hay thiết bị liên lạc khi chưa được cho phép.",
      "Không trao đổi bài, nhìn bài, nhờ người thi thay, làm hộ bài hoặc can thiệp trái phép vào bài thi và hệ thống học tập.",
      "Không sao chép bài tập, báo cáo, mã nguồn hoặc kết quả của người khác mà không trích dẫn; chỉ sử dụng công cụ hỗ trợ khi học phần cho phép và phải khai báo theo yêu cầu.",
      "Vi phạm có thể dẫn đến lập biên bản, hủy kết quả bài thi/học phần hoặc xem xét kỷ luật theo quy trình và quy chế chính thức của trường.",
    ],
  },
  {
    title: "Đăng ký và rút học phần",
    icon: "bookopen",
    points: [
      "Kiểm tra môn tiên quyết, lịch học, giới hạn tín chỉ, sĩ số và thời hạn trước khi xác nhận đăng ký.",
      "Chỉ thay đổi hoặc rút học phần qua quy trình được nhà trường công bố; lưu xác nhận sau khi thao tác.",
      "Đăng ký trùng lịch hoặc không đáp ứng điều kiện có thể không được công nhận; không tự ý tham gia lớp chưa có xác nhận.",
    ],
  },
  {
    title: "Học phí và thời hạn",
    icon: "wallet",
    points: [
      "Đối chiếu khoản phải nộp, hạn thanh toán và hướng dẫn trên thông báo chính thức của nhà trường.",
      "Giữ chứng từ thanh toán và liên hệ bộ phận phụ trách nếu số liệu chưa khớp; không gửi thông tin tài khoản hoặc mật khẩu qua đường dẫn không xác thực.",
      "Khoản quá hạn có thể ảnh hưởng việc đăng ký, dự thi hoặc xác nhận học vụ nếu quy định hiện hành có nêu.",
    ],
  },
  {
    title: "Ứng xử và bảo vệ thông tin",
    icon: "users",
    points: [
      "Tôn trọng giảng viên, nhân viên và người học; không quấy rối, đe dọa, phân biệt đối xử hoặc phá hoại tài sản, hệ thống.",
      "Bảo vệ tài khoản, không chia sẻ mật khẩu và chỉ truy cập hồ sơ được phép; báo ngay khi phát hiện sai lệch hoặc lộ thông tin.",
      "Thực hiện hướng dẫn an toàn tại lớp học, phòng thí nghiệm và các khu vực có yêu cầu riêng.",
    ],
  },
  {
    title: "Khiếu nại và đề nghị xem xét",
    icon: "file",
    points: [
      "Gửi đề nghị đúng bộ phận, đúng thời hạn; nêu rõ học phần/sự việc và đính kèm minh chứng cần thiết.",
      "Giữ mã tiếp nhận hoặc xác nhận gửi hồ sơ để theo dõi; không chỉnh sửa hoặc làm sai lệch minh chứng.",
      "Nếu chưa rõ quy định, hỏi Phòng Đào tạo hoặc xem văn bản gốc trước khi đưa ra quyết định học vụ.",
    ],
  },
];

export default function RegulationsSection({ onLogin }) {
  return (
    <section className="landing-section policy-section" id="regulations">
      <div className="section-heading policy-heading">
        <div>
          <span className="section-kicker">CẨM NANG HỌC VỤ</span>
          <h2>Quy định và những điều sinh viên cần lưu ý</h2>
        </div>
        <p>
          Chủ động nắm lịch học, quy trình học vụ và trách nhiệm học thuật để
          bảo vệ quyền lợi của mình trong mỗi học kỳ.
        </p>
      </div>
      <div className="policy-alert" role="note">
        <Icon name="alert" size={24} />
        <div>
          <strong>Thông tin quan trọng</strong>
          <p>
            Nội dung dưới đây là hướng dẫn tham khảo, không thay thế quy chế,
            đề cương học phần hoặc thông báo chính thức. Mức chuyên cần, hình
            thức xử lý và thời hạn cụ thể cần căn cứ văn bản hiện hành của
            trường. Khi có khác biệt, áp dụng văn bản chính thức.
          </p>
        </div>
      </div>
      <div className="policy-list">
        {regulations.map((item, index) => (
          <article className="policy-card" key={item.title}>
            <div className="policy-card-heading">
              <span className="policy-index">{String(index + 1).padStart(2, "0")}</span>
              <span className="policy-icon">
                <Icon name={item.icon} size={21} />
              </span>
              <h3>{item.title}</h3>
              {item.warning && (
                <span className="policy-warning">{item.warning}</span>
              )}
            </div>
            <ul>
              {item.points.map((point) => (
                <li key={point}>{point}</li>
              ))}
            </ul>
          </article>
        ))}
      </div>
      <div className="policy-contact">
        <div>
          <strong>Cần xác nhận quy định cho trường hợp cụ thể?</strong>
          <p>Liên hệ Phòng Đào tạo và cung cấp mã sinh viên, học phần, minh chứng liên quan.</p>
        </div>
        <button className="button-solid" onClick={onLogin}>
          Vào cổng đào tạo <Icon name="arrow" size={16} />
        </button>
      </div>
    </section>
  );
}
