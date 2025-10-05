
<H1>Database: The ELT pipeline </H1>

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



