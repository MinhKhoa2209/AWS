# Trả lời 5 câu hỏi đánh giá tuần

## Q1. Responsibility

- Phụ trách phần hardening cho ứng dụng W5 theo chủ đề "The Network Fortress".
- Các việc chính: kiểm tra network visibility, cấu hình firewall/security control, thêm file storage dùng chung, thiết lập backup/restore, đưa API Gateway trước Lambda và áp dụng scaling pattern.
- Chia công việc theo 5 must-haves của W5, test từng phần và lưu evidence ngay sau khi hoàn thành => đảm bảo kịp deadline thuyết trình Thứ Sáu.

## Q2. Quality of Work

- Bám sát yêu cầu W5: ứng dụng phải chạy end-to-end, kiến trúc phải khớp deployment thật và mỗi must-have đều có bằng chứng kiểm chứng.
- Kiểm tra cả positive test và negative test, ví dụ request hợp lệ trả 200, request thiếu auth trả 403, traffic bị chặn được ghi nhận trong log.
- Backup không chỉ dừng ở việc tạo plan mà có restore test và đọc lại data sau khôi phục => đảm bảo chất lượng theo tiêu chí production-grade.

## Q3. Collaboration

- Hỗ trợ nhóm gom yêu cầu W5 thành các phần dễ theo dõi: MH1 connectivity, MH2 firewall, MH3 storage/backup, MH4 API Gateway, MH5 Lambda scaling.
- Ghi lại các evidence cần có để từng thành viên biết cần test gì, chụp gì và đưa vào phần nào của `docs/W5_evidence.md`.
- Thống nhất cách trình bày cho demo: app end-to-end, log network, request bị chặn/được cho phép, file đọc từ storage, restore result và API test => giúp phần thuyết trình mạch lạc hơn.

## Q4. Initiative

- Chủ động đọc kỹ W5 announcement để tránh hiểu sai mục tiêu: không xây ứng dụng mới, mà làm hệ thống hiện có chắc hơn và dễ verify hơn.
- Bổ sung hướng dẫn evidence và checklist demo để nhóm không bỏ sót các tiêu chí bắt buộc.
- Ưu tiên các phần có rủi ro bị trừ điểm cao như restore test, API auth 200/403, Flow Logs và negative security test => giảm rủi ro khi trainer verify.

## Q5. Communication

- Cập nhật nội dung qua các file Markdown như `docs/W5_evidence.md`, `docs/W5_project_announcement_vi.md`, `docs/W5_learner_guide_vi.md` và `docs/W5_presentation_script_vi.md`.
- Tài liệu tập trung vào mục tiêu W5, evidence cần nộp, thứ tự demo và các điểm trainer sẽ verify.
- Truyền đạt ngắn gọn theo từng must-have và kết quả cần chứng minh => giúp nhóm dễ theo dõi tiến độ và chuẩn bị presentation đúng trọng tâm.
