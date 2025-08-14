# 🏨 Hotel Data Warehouse: From SQL to Interactive Dashboard

<img width="1033" height="590" alt="Screenshot 2025-07-31 at 20 00 59" src="https://github.com/user-attachments/assets/f86e03cd-dc5d-4663-9651-bb8e44860f31" />


## 📌 Project Overview
This project showcases the complete journey from **data warehousing in SQL Server** to creating an **interactive Power BI dashboard**.  
The goal was to model, clean, and transform hotel booking, search, and traffic data into a **well-structured star schema** with **shared dimensions** — a challenging but crucial step to enable cross-table analysis.

The process involved:
- Designing **shared** and **table-specific dimension tables**.
- Building fact tables with strong foreign key relationships.
- Applying **null handling** and **data type standardization**.
- Building relationships and measures in Power BI.
- Creating an interactive dashboard for **hotel booking analytics**.

---

## 🛠️ Project Steps

### 1️⃣ Data Modeling in SQL Server
- Designed **shared dimensions** (`dim_date`, `dim_origin`, `dim_destination_geo`, `dim_currency`) used across multiple fact tables — a challenging part of the project that required careful key alignment.
- Created **table-specific dimensions** (e.g., `dim_page_type`, `dim_browser_os`) for certain datasets.
- Built **fact tables** (`fact_booking_transaction`, `fact_search_transaction`, `fact_traffic_transaction`) referencing dimensions via foreign keys.
- Applied **NULL handling rules** (e.g., replacing `NULL` IDs with `-1`, creating “Unknown” categories).
- Ensured **data type consistency** across tables.

### 2️⃣ Data Transformation
- Joined raw transactional data with dimensions using SQL.
- Applied **casting & formatting** for date and time fields.
- Cleaned data to remove inconsistencies before Power BI import.

### 3️⃣ Power BI Data Preparation
- Imported SQL Server data into Power BI.
- Used **Power Query** for:
  - Filtering invalid records.
  - Renaming and standardizing columns.
  - Creating calculated columns (e.g., `Length of Stay`).

### 4️⃣ Data Modeling in Power BI
- Established **relationships** between fact and dimension tables in Model View.
- Created **DAX measures** for:
  - KPIs: `Total Bookings`, `Cancellation Rate`, `Average Stay Length`.
  - Currency-based searches and destination analysis.

### 5️⃣ Dashboard Design
The dashboard includes:
- KPI cards for quick performance insights.
- Booking trend line chart.
- Top origin/destination countries by bookings.
- Currency breakdown for searches.
- Most viewed page type.
- Tree map for searched destinations.

---

## 📊 Key Insights
- **Thailand** is the top destination (408 bookings), followed by China and Singapore.
- **Cancellation rate** is low (0.6%), showing strong booking intent.
- **Average stay length** is 2.53 days — indicating mostly short leisure trips.
- **USD** dominates in searches (22.3%), showing a large international user base.
- Mobile vs desktop browsing patterns differ, with mobile users focusing more on hotel pages.

---

## ✅ Conclusion
This project goes beyond creating a dashboard:
- **Backend:** Structured data warehouse with shared and table-specific dimensions.
- **Data Cleaning & Transformation:** SQL + Power Query for high-quality, reliable data.
- **Frontend:** Power BI model with DAX, relationships, and interactive visuals.

The result is a **scalable and maintainable** analytics solution that supports cross-table insights and can easily adapt to new datasets.

---

## 📂 Repository Structure


---

## 🖥️ Technologies Used
- **SQL Server**
- **Power BI**
- **Power Query**
- **GitHub**

---

## 📌 Author
**Elnaz Sh**  
[GitHub Profile](https://github.com/elnazshzi)


