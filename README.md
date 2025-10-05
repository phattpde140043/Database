
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


