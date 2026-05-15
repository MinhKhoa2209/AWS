---
title: "Script trình bày W5 - XOPS"
---

# Script trình bày W5 - XOPS

## Mở đầu

Ở các tuần trước, project đã có luồng ứng dụng chính: người dùng truy cập frontend qua CloudFront, static files nằm trong S3 private bucket, request API đi qua CloudFront tới Application Load Balancer, backend chạy bằng ECS Fargate trong private subnet, dữ liệu chính nằm ở DocumentDB, và phần RAG/AI được xử lý bằng Lambda kết nối Bedrock.

Tuần này nhóm không đổi core stack của ứng dụng. Mục tiêu là làm stack hiện có production-grade hơn: network quan sát được, egress được kiểm soát tại biên, app tier có shared file storage, stateful resources có backup và restore test, còn Lambda RAG được đặt sau API Gateway thay vì gọi trực tiếp.

## Part 1 - Application Recap

Ứng dụng XOPS được thiết kế như một hệ thống 3-tier.

Tầng presentation là CloudFront và S3. S3 không public trực tiếp; CloudFront dùng Origin Access Control để đọc frontend từ bucket private. Lý do chọn cách này là frontend vẫn phục vụ được toàn cầu qua edge location, nhưng object trong S3 không bị mở public.

Tầng application là ALB và ECS Fargate. ALB là entry point cho backend HTTP và websocket path. ECS Fargate giúp nhóm chạy container backend mà không phải quản lý EC2 worker node. Backend được đặt trong private app subnet, không gán public IP, và runtime secret lấy từ Secrets Manager.

Tầng data là DocumentDB trong private data subnet. DocumentDB là database chính của ứng dụng, nên nó không cần route internet trực tiếp. Chỉ app tier được phép kết nối tới database thông qua security group.

Tầng AI là Lambda RAG và Bedrock. Lambda giữ phần xử lý RAG/serverless, còn Bedrock là managed model runtime. Ở W5, Lambda này được đưa ra sau API Gateway để có surface API chuẩn hơn.

Trong demo carry-forward, nhóm sẽ chứng minh app vẫn chạy end-to-end sau khi thêm các lớp hardening: frontend load qua CloudFront, backend trả response qua ALB, và luồng RAG vẫn đi qua API Gateway tới Lambda.

## Part 2 - W5 Architecture

### MH1 - Justified Single-VPC

Với MH1, nhóm chọn Path C: Justified Single-VPC.

Lý do không chọn multi-VPC là vì project hiện tại là một ứng dụng 3-tier nằm trong cùng một trust boundary. Backend ECS cần nói chuyện trực tiếp với DocumentDB, EFS và các endpoint phục vụ RAG. Các thành phần này thuộc cùng một project, cùng lifecycle triển khai, cùng team vận hành, và chưa có yêu cầu tách domain mạng theo team, theo account, hoặc theo business unit.

Nếu dùng VPC Peering lúc này, nhóm sẽ tạo thêm một VPC chỉ để nối lại các thành phần vốn đang thuộc cùng một ứng dụng. Điều đó làm route table, CIDR planning, DNS resolution, security group reference, Flow Logs và firewall path phức tạp hơn, nhưng chưa giải quyết một vấn đề thật của project.

Nếu dùng Transit Gateway, complexity còn cao hơn. TGW phù hợp khi có nhiều VPC, cần transitive routing, shared services VPC, VPN hoặc Direct Connect về on-prem. XOPS hiện chưa có nhiều VPC độc lập và chưa có nhu cầu hub-and-spoke. Dùng TGW ở giai đoạn này sẽ tăng chi phí và tăng surface vận hành mà không tạo thêm isolation có ý nghĩa.

Vì vậy quyết định đúng hơn là giữ single VPC. Trong VPC bao gồm multi-AZ, có public subnets cho ALB/NAT, firewall subnets riêng cho Network Firewall endpoint, private app subnets cho ECS và ops-runner, private data subnets cho DocumentDB. Nhóm bật VPC Flow Logs cho toàn bộ VPC và tách subnet theo chức năng, tách security group theo workload, route private app subnet qua firewall trước khi ra NAT, và đặt data layer trong private subnet riêng.

Nếu sau này project có môi trường production và staging tách account hoặc có shared service VPC cho nhiều app, hoặc cần kết nối on-prem qua VPN/Direct Connect, lúc đó nhóm sẽ thêm VPC thứ hai và cân nhắc Transit Gateway. Còn ở hiện tại, single VPC multi-AZ là quyết định có chủ đích và phù hợp với scope của XOPS.

### MH2 - Network Firewall Hardening

Với MH2, nhóm chọn deploy AWS Network Firewall.

Lý do là app tier của XOPS có outbound internet qua NAT Gateway. Backend có thể cần gọi các public service hoặc public AWS endpoint, ví dụ API Gateway endpoint, provider bên ngoài, hoặc các integration khác. Khi đã có egress qua NAT, chỉ dùng Security Group là chưa đủ.

Security Group rất tốt để kiểm soát resource nào được kết nối tới resource nào, nhưng Security Group không phải lớp inspection egress theo domain hoặc signature. NAT Gateway cũng chỉ dịch địa chỉ, không quyết định request nào nên bị chặn theo chính sách bảo mật.

Network Firewall được đặt trong firewall subnet riêng. Route từ private app subnet đi internet không đi thẳng ra NAT mà đi qua firewall endpoint trước. Sau khi traffic được inspect, firewall mới chuyển tiếp qua NAT Gateway để ra ngoài.

Trong stack này, nhóm cấu hình stateful rule group để phục vụ negative test: domain demo bị chặn sẽ tạo Alert Log, còn request hợp lệ vẫn đi qua NAT và có thể quan sát bằng Flow Logs. Như vậy nhóm chứng minh được cả hai mặt: security control thật sự chặn được traffic không mong muốn, và traffic hợp lệ vẫn hoạt động.

Mục đích của service này trong project không phải chỉ để "có firewall", mà là để ép buộc egress path. Nếu private workload muốn ra internet, nó phải đi qua điểm kiểm soát chung, có log, có policy, và có bằng chứng khi bị chặn.

### MH3 - File Storage Layer và Backup Plan

Với MH3, nhóm thêm Amazon EFS làm shared file storage.

Trong môi trường container, file nằm trong task hoặc instance không nên được xem là persistent data. ECS task có thể bị thay thế, scale out hoặc redeploy. Nếu mỗi task giữ file cục bộ thì dữ liệu bị phân mảnh và không sống độc lập với lifecycle của compute.

EFS giải quyết vấn đề đó bằng một filesystem chung, managed, có thể mount từ app tier trong private subnet. Nhóm tạo mount target ở hai AZ để phù hợp với kiến trúc multi-AZ. Security group của EFS chỉ allow NFS từ app tier hoặc ops-runner, không mở ra 0.0.0.0/0.

Trong project, EFS được dùng để đại diện cho lớp file dùng chung của ứng dụng: file upload, generated artifact, hoặc file phục vụ kiểm tra restore. Ops-runner private EC2 mount EFS để nhóm có thể chứng minh ghi và đọc file thật từ path đã mount, không phải test rời trên máy local.

Phần thứ hai của MH3 là backup. Nhóm dùng AWS Backup vì stateful resources không chỉ có database. XOPS có ít nhất ba loại state cần bảo vệ: EFS cho shared file, EBS root volume của ops-runner, và DocumentDB cho dữ liệu ứng dụng.

Backup plan có backup vault mã hóa bằng KMS, schedule daily và retention 7 ngày. Nhưng điểm nhóm muốn nhấn mạnh là backup chưa restore thì chưa đủ. Vì vậy evidence cần có restore job Completed và bước đọc lại dữ liệu đã biết từ resource được khôi phục.

Mục đích của AWS Backup trong project là gom policy backup của nhiều resource stateful về một nơi, thay vì mỗi service tự backup rời rạc. Điều này giúp trainer kiểm tra được vault, recovery point, job status và restore result một cách rõ ràng.


### MH4 - API Gateway trước Lambda

Với MH4, nhóm đặt REST API Gateway trước Lambda RAG.

Trước đó, nếu backend gọi Lambda trực tiếp thì Lambda chỉ là function nội bộ. Cách đó chạy được trong dev, nhưng chưa phải một API surface tử tế: khó áp throttling theo client, khó kiểm soát API key ở tầng edge của function, và frontend hoặc service khác không có một endpoint chuẩn để gọi.

Nhóm chọn REST API Gateway thay vì chỉ giữ HTTP API vì yêu cầu W5 cần API Key và Usage Plan. REST API Gateway hỗ trợ API key, usage plan, rate limit và burst limit theo cách phù hợp với tiêu chí 200/403 của bài.

Route chính là `POST /rag`, tích hợp Lambda Proxy Integration tới Lambda RAG. Method yêu cầu `x-api-key`. Usage plan đặt throttling để giới hạn tốc độ request, ví dụ rate limit 10 requests/giây và burst 20.

Backend được cấu hình gọi API Gateway invoke URL thay vì invoke Lambda trực tiếp. Như vậy Lambda RAG không còn là function bị gọi tùy tiện, mà nằm sau một API layer có authentication tối thiểu, throttling và log rõ ràng.

Test của MH4 rất trực tiếp: request có `x-api-key` hợp lệ trả 200, request không có key trả 403. Hai kết quả này chứng minh API Gateway đang thực thi policy trước khi request tới Lambda.

### MH5 - Serverless Scaling Pattern

MH5 nhóm áp dụng Provisioned Concurrency cho Lambda RAG alias `live`.

Function RAG nằm sau API Gateway, nên latency ảnh hưởng trực tiếp tới trải nghiệm người dùng. Provisioned Concurrency pre-warm Lambda để giảm cold start cho path này. Nhóm cấu hình provisioned concurrent executions bằng 1 cho alias `live`, sau đó dùng CloudWatch metric hoặc trace để so sánh init duration trước và sau.

Trong presentation chính, nhóm chỉ nhắc ngắn MH5 vì trọng tâm câu hỏi hôm nay là MH1 tới MH4, nhưng evidence vẫn cần thể hiện function thật, alias thật và metric thật.

Cue demo MH5: show Lambda alias `live`, provisioned concurrency status READY, và metric/trace liên quan cold start.

## Part 3 - Q&A Prep

### Câu hỏi: Vì sao không dùng multi-VPC cho đúng đề networking?

Trả lời: Đề cho phép ba path, trong đó Path C là Justified Single-VPC. XOPS chưa có nhiều trust boundary độc lập. ECS, DocumentDB, EFS và RAG đều thuộc cùng một ứng dụng, cùng team vận hành. Multi-VPC lúc này tạo thêm route, CIDR, DNS và firewall complexity mà chưa đem lại isolation thực tế. Nhóm chọn single VPC nhưng làm đúng production pattern: multi-AZ, subnet tách tầng, Flow Logs, firewall subnet riêng và private data subnet.

### Câu hỏi: Khi nào nhóm sẽ thêm VPC thứ hai?

Trả lời: Khi có boundary thật. Ví dụ production và staging tách account, partner integration cần network riêng, shared service VPC phục vụ nhiều ứng dụng, hoặc cần kết nối on-prem qua VPN/Direct Connect. Nếu có từ ba VPC trở lên hoặc cần transitive routing, nhóm sẽ cân nhắc Transit Gateway.

### Câu hỏi: Vì sao cần Network Firewall nếu đã có Security Group?

Trả lời: Security Group kiểm soát traffic ở resource level, còn Network Firewall kiểm soát egress path tập trung ở biên VPC. Vì private app subnet có route ra NAT, nhóm cần một lớp inspect trước NAT để chặn domain/signature không mong muốn và tạo alert log. NAT không tự làm việc này.

### Câu hỏi: Vì sao dùng EFS mà không dùng S3 cho file?

Trả lời: S3 tốt cho object storage, nhưng MH3 yêu cầu file storage layer có mount path cho app tier. EFS phù hợp khi workload cần POSIX filesystem chung, có thể mount từ ECS hoặc EC2 trong private subnet. Với upload hoặc artifact cần path filesystem, EFS đúng hơn S3.

### Câu hỏi: Backup plan có gì hơn snapshot thủ công?

Trả lời: AWS Backup cho phép gom backup policy của nhiều loại resource vào một vault và một plan: EFS, EBS và DocumentDB. Quan trọng nhất là nhóm không chỉ tạo backup, mà còn chạy restore test và đọc lại data đã biết. Điều này chứng minh backup dùng được khi sự cố xảy ra.

### Câu hỏi: Vì sao dùng REST API Gateway?

Trả lời: Vì yêu cầu của MH4 cần API key, usage plan và throttling. REST API Gateway hỗ trợ trực tiếp API Key và Usage Plan, nên phù hợp để chứng minh request có key trả 200 và thiếu key trả 403.

### Câu hỏi: API key có phải authentication mạnh không?

Trả lời: API key không thay thế user authentication mạnh như Cognito hoặc JWT. Trong scope W5, API key được dùng để đáp ứng yêu cầu auth/throttling ở API Gateway và bảo vệ Lambda khỏi request không có key. Nếu lên production thật, nhóm sẽ thêm Cognito/JWT authorizer hoặc IAM auth tùy loại client.

## Part 4 - Deployment Demo Flow

### Demo 1 - Carry-forward app

Đầu tiên nhóm mở CloudFront URL để chứng minh frontend vẫn chạy. Sau đó thực hiện một action đại diện trong app để backend trả response qua ALB/ECS. Nếu có phần RAG, nhóm gửi một câu hỏi để chứng minh API Gateway, Lambda và Bedrock vẫn hoạt động end-to-end.

Điểm cần nói: "Các lớp hardening W5 không thay thế app cũ, mà bao quanh app cũ. Vì vậy app phải vẫn chạy được."

### Demo 2 - MH1 Flow Logs

Mở VPC trong AWS Console và chỉ cấu trúc subnet multi-AZ: public, firewall, private app, private data. Sau đó mở CloudWatch log group của VPC Flow Logs.

Nói: "Đây là bằng chứng network observable. Nhóm không chỉ vẽ route, mà có Flow Logs để kiểm tra traffic thật."

Show sample ACCEPT. Nếu có sample REJECT, show thêm để chứng minh negative path.

### Demo 3 - MH2 Firewall allow/block

Show route table private app subnet có default route đi tới firewall endpoint. Sau đó show firewall route tiếp về NAT.

Chạy request hợp lệ hoặc show output request hợp lệ. Tiếp theo chạy request tới domain demo bị chặn. Mở Network Firewall Alert Logs và chỉ event tương ứng.

Nói: "Request private app ra internet không đi thẳng tới NAT. Nó bị ép đi qua Network Firewall trước, nên policy egress có thể được enforce và audit."

### Demo 4 - MH3 EFS và Backup

Mở EFS file system và mount targets ở hai AZ. Show security group chỉ allow NFS từ app/ops-runner security group.

Mở ops-runner private instance hoặc output healthcheck. Ghi một file vào mount path, đọc lại file đó.

Sau đó mở AWS Backup: backup vault, backup plan daily retention 7 ngày, backup selection gồm EFS, ops-runner/EBS và DocumentDB. Show completed backup job và completed restore job. Cuối cùng show data đọc lại từ resource restore.

Nói: "Điểm chính là restore test. Backup job completed chưa đủ; nhóm phải chứng minh recovery point có thể khôi phục và dữ liệu đọc lại được."

### Demo 5 - MH4 API Gateway

Mở REST API Gateway, resource `/rag`, method POST, Lambda proxy integration, API key required. Mở usage plan để chỉ rate limit, burst limit và API key attached.

Chạy curl có key:

```powershell
curl -X POST "$RAG_API_URL/rag" -H "x-api-key: $RAG_API_KEY" -H "Content-Type: application/json" -d "{\"question\":\"health check\"}"
```

Kết quả mong đợi: HTTP 200.

Chạy curl thiếu key:

```powershell
curl -X POST "$RAG_API_URL/rag" -H "Content-Type: application/json" -d "{\"question\":\"health check\"}"
```

Kết quả mong đợi: HTTP 403.

Nói: "Hai test này chứng minh API Gateway đang thực thi auth/throttling surface trước Lambda, thay vì để client gọi Lambda trực tiếp."

### Demo 6 - MH5 Provisioned Concurrency

Mở Lambda RAG, alias `live` và provisioned concurrency. Show trạng thái READY hoặc metric liên quan.

Nói ngắn: "Vì Lambda này nằm trên request path của RAG, nhóm dùng Provisioned Concurrency để giảm cold start. Đây là scaling pattern được apply lên function thật của ứng dụng."

