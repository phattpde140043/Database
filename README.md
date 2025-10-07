
<H1>Database: The ELT pipeline </H1>

<h3>Cấu trúc thư mục:</h3>
<ul>
  <li><b>database_script:</b> Script implement Database trên PostgreSQL</li>
  <li><b>airflow/dags:</b> Các scheduled job hoạt động trên airflow</li>
  <li><b>Databricks: </b>Script implement Warehouse trên Databricks và các data pipelines</li>
  <li><b>Project Report:</b> File Report tổng hợp quá trình thiết kế dự án</li>
</ul>

<H3>Mô hình dự án: </H3>
<img alt="image" width="100%" height="auto" src="https://github.com/user-attachments/assets/3b3841c6-1406-4b76-8562-7c0ff22f4dad" />
<H3>Tổng quan dự án: </H3>
<p>Công ty giả định hoạt động trong lĩnh vực thương mại điện tử với ba mảng hệ thống chính:</p>
<ol>
  <li><b>PoS (Point of Sale – Bán hàng)</b></li>
  <ul>
    <li>Quản lý giao dịch tại cửa hàng và kênh online.</li>
    <li>Dữ liệu phát sinh liên tục, khối lượng lớn (hàng triệu order/tháng).</li>
  </ul>
  <li><b>Logistics (Kho vận & vận chuyển)</b></li>
    <ul>
    <li>Theo dõi tình trạng tồn kho, điều phối vận chuyển, giao hàng.</li>
    <li>o	Yêu cầu tích hợp dữ liệu từ nhiều chi nhánh/kho khác nhau.</li>
  </ul>
  <li><b>ERP (Enterprise Resource Planning – Quản lý vận hành)</b></li>
    <ul>
    <li>Bao gồm quản lý nhân sự, tài chính, mua hàng, CMS nội bộ.</li>
    <li>Nhiều dữ liệu nhạy cảm, yêu cầu phân quyền và kiểm soát chặt chẽ</li>
  </ul>
</ol>
<h3>Giải pháp triển khai:</h3>
<ul>
  <li><b>Cơ sở dữ liệu giao dịch (OLTP): </b>PostgrSQL cho từng microserice</li>
  <li><b>Streaming ingestion:</b> Kafka/Debezium để đồng bộ dữ liệu realtime về Data lake</li>
  <li><b>Batch ingestion: </b>Sử dụng Airflow để tạo các scheduled job nhằm load dữ liệu lên warehouse theo script</li>
  <li><b>Data lakehouse: </b>Databricks theo mô hình Medallion</li>
</ul>

<h3>Yêu cầu kĩ thuật lớp OLTP:</h3>
<ul>
<li><b>Audit & Logging:</b> Các thao tác trên database phải được ghi lại log.</li>
<li><b>PII Protection:</b> Các dữ liệu PII phải được mã hoá và chỉ có thể truy cập trên một role nhất định được cấp.</li>
<li><b>RBAC:</b>  nguyên tắc Least Privilege- mỗi role chỉ được cấp quyền đúng theo nhu cầu sử dụng.</li>
<li><b>Data Integrity & Constraints:</b> Bắt buộc PK, FK, Unique, Check để đảm bảo toàn vẹn. Duy trì referential integrity kể cả khi soft delete.</li>
<li><b>Backup & Recovery:</b> Phải có phương án backup (full backup và incremental backup) và recover dữ liệu định kỳ.</li>
<li><b>Performance & Scalability:</b> Các dữ liệu được truy vấn thường xuyên được indexing và partition để đảm bảo hiệu suất truy vấn.</li>
<li><b>Soft Delete & Data Lifecycle:</b> Các dữ liệu được thiết kế để soft-deleted và có các trigger để xử lý dữ liệu liên quan sau khi delete.</li>
<li><b>Dữ liệu đảm bảo tiêu chuẩn ACID.</b></li>
<li><b>View Layer for Data Access:</b> Tạo lớp View để truy cập dữ liệu nhằm hạn chế các request trên database.</li>
<li><b>Retention Limit:</b> Để đảm bảo hiệu suất, Database chỉ lưu dữ liệu active và đã unactive trong 3 tháng. Các dữ liệu cũ hơn sẽ được đồng bộ và lưu tại warehouse</li>
</ul>

<h3>Cấu trúc luồng ELT</h3>
<h4>Streaming Ingestion:</h4>
<p><b>Quy trình:</b></p>
<ul>
  <li> Triển khai cấu hình kafka, Debezium. kích hoạt WAL trong PostgreSQL.</li>
  <li> Debezium theo dõi các dữ liệu WAL của postgreSQL và chuyển thành message bằng Kafka</li>
  <li> Databricks có các luồng streaming liên tục nhận dữ liệu từ Kafka và đưa vào bảng của layer Bronze.
</ul>
<h4>Batch Ingestion:</h4>
<p><b>Quy trình: </b></p>
<ul>
  <li>Viết các DAGS airflow và cấu hình scheduled job định kỳ truy vấn dữ liệu mới trên PostgreSQL bằng watermark.</li>
  <li>Dữ liệu được lưu thành file Parquet sau đó đẩy vào các folder trong cloud storage như S3.</li>
  <li>Có các luồng AutoLoader với option alvailabeNow định kỳ kích hoạt và quét các thư mục này và xử lý dữ liệu nạp vào bảng Bronze.</li> 
</ul>
<h3>Cấu trúc lớp Warehouse:</h3>
<h4>Kiến trúc tổng thể mô hình Medallion:</h4>
<ul>
  <li><b>Bronze Layer:</b>Lưu trữ dữ liệu thô từ các nguồn database khác nhau và cho phép tích hợp từ rất nhiều nguồn dữ liệu khác và các kiểu dữ liệu khác. Lưu trữ với định dạng gốc nhằm đảm bảo "source of truth" dễ dàng truy vấn ngược, khắc phục lỗi cũng như kiểm toán dữ liệu</li>
  <li><b>Silver Layer:</b> Dữ liệu được lấy từ tầng bronze chuẩn hóa tất cả dữ liệu từ nhiều nguồn về một định dạng duy nhất. Đảm bảo dữ liệu tại tâng này là dữ liệu mới nhất hiện tại.</li>
  <li><b>Gold Layer:</b> Dữ liệu từ tầng Silver được làm giàu, dựa trên các dữ liệu đấy sẽ xử lý theo 2 hướng: </li>
  <ul>
    <li>Dữ liệu được join với nhau và tính toán sau đó lưu thành các view để làm nguồn dữ liệu cho các báo cáo vận hành.</li>
    <li>Dữ liệu trải qua các kĩ thuật khai phá dữ liệu, khai thác thêm các feature cần thiết để làm tài nguyên cho các kĩ thuật ML, AI</li>
  </ul>
</ul>

<h3>Yêu cầu kĩ thuật với lớp OLAP</h3>
<ul>
  <li>Cơ chế phân quyền phải đảm bảo RBAC:</li>
  <ul>
    <li>Bronze layer: Đây là tầng dữ liệu Raw nhất. chỉ có thành viên trong nhóm Data Engineer có quyền truy cập. </li>
    <li>Silver layer: Đây là dữ liệu đã chuẩn hóa. ngoài đội ngữ Data Engineer truy cập thì Data Analyst và Data Scientist cũng có thể truy cập bảng với quyền READ(tuy nhiên, tốt nhất chỉ nên tiếp xúc với View tạo sẵn)</li>
    <li>Gold layer: Đây là dữ liệu business-friendly. ngoài DE và DS thì các role Business Analyst, BI Dev cũng nên có quyền READ qua các view được chỉ định trước tùy theo scope của công việc.</li>
    <li>Ngoài phân quyền theo role công việc, một số bảng dữ liệu quan trọng nên được bảo mật và chỉ cấp quyền cho những thành viên trong nhóm có task liên quan. và cần thu hồi quyền sau khi hoàn thành.</li>
  </ul>
  <li>Partition Strategy & Query performance </li>
  <ul>
    <li>Bronze layer: query chủ yếu là luồng load dữ liệu lên tầng Silver. nên các bảng trong tầng này chủ yếu partition theo ingestion_time (daily/monthly tùy thuộc vào quy mô dự án)</li>
    <li>Silver layer: cần thiết kế partition strategy theo nghiệp vụ. tập trung vào các cột thường dùng là điều kiện truy vấn.</li>
    <li>Gold layer: Tập trung phục vụ business query và BI dashboards. Nhiều trường hợp Gold table đã ở mức aggregated/denormalized → có thể không cần partition phức tạp.</li>
    <li>Min mỗi partition nên là 1 GB.</li>
    <li>Ngoài cơ chế partition thì nên sắp xếp các cột của bảng hợp lý để tận dụng thêm khả năng data skipping của statistics.</li>
    <li>Nếu có nhiều cột cần query ngoài partition thì sử dụng thêm Z-order.</li>
    <li>Query phức tạp lặp lại → cân nhắc Materialized view ở Gold layer.</li>
    <li>Cân nhắc trade-off: tránh partition theo cột high-cardinality (vd: user_id) để không sinh quá nhiều file nhỏ.</li>
  </ul>
</ul>
<li>Audit & Logging</li>
<ul>
  <li>Kích hoạt chức năng Unity Catalog audit logs cho mọi hành động và có thể lưu vào cloud storage.</li>
  <li>Kích hoạt Delta Table Change Data Feed để theo dõi sự thay đổi dữ liệu ở  các bảng.</li>
  <li>Thêm các cột metadata cần thiết ở các bảng như (batch_id/run_id, source system + ingestion timestamp, checksum/hash) để quản lý và tracing data.</li>
  <li>Thiết kế một bảng chứa log cho các data pipeline được scheduled để theo dõi hoạt động của hệ thống.</li>
  <li>Thông tin cần log:</li>
  <ul>
    <li>job_id, task_id, user.</li>
    <li>start_time, end_time, duration.</li>
    <li>input_rows, output_rows</li>
    <li>error stacktrace (nếu có)</li>
  </ul>
</ul>
<li> PII Protection:</li>
<ul>
  <li>Sử dụng Centralized Access Control của Unity Catalog để giới hạn truy cập dữ liệu PII.</li>
  <li>Sử dụng Column Masking Policies cho các cột chứa PII.</li>
  <li>Sử dụng Row-Level Security khi thiết kế query của end user trong trường hợp user  thuộc role được quyền xem thì chỉ xem được dữ liệu thuộc scope quản lý của mình.</li>
  <li>Sử dụng Customer Managed Keys (CMK) thay cho mã hóa mặc định của Databricks đối với dữ liệu At Rest.</li>
  <li>Key-rotation định kỳ.</li>
</ul>
<li>Data Integrity & Constraint:</li>
<li>Backup & Recovery:</li>

