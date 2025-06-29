# AWS Secure Storage and Access Control

This project provisions a **secure, production-ready AWS infrastructure** using Terraform. It is designed for small businesses or professional environments such as clinics, law firms, or consultancies that need:

- Secure file storage (with versioning, encryption, lifecycle rules)
- Structured user access control (doctors, receptionists, IT, admins)
- Auditing and monitoring (via CloudTrail and CloudWatch)
- Budget awareness and cost control (via alerts and thresholds)

---

##  Key Components

### 1. **Amazon S3 (Storage)**
- **Primary S3 bucket** for storing client or business files
- **Logging bucket** for capturing access logs from the main bucket
- **Versioning** enabled to track file changes and allow rollbacks
- **Server-side encryption** (AES-256) enforced by default
- **Lifecycle rule** that archives objects to Glacier after 365 days
- **Access logging** that sends logs to a separate, secure bucket

### 2.  **IAM User & Group Access Control**
- IAM users automatically created for different staff roles:
  - Doctors
  - Admins
  - Reception
  - IT Team
- Each user is:
  - Assigned to a group based on role
  - Given a login profile with forced password reset
- IAM groups receive tailored policies:
  - **Doctors:** Limited read/write S3 access
  - **Admins:** Full administrative access
  - **Reception:** Read-only access to files
  - **IT Team:** Full access to S3, CloudWatch, and CloudTrail

### 3.  **Auditing via CloudTrail**
- **Multi-region CloudTrail** configured to track all account activity
- **Log file validation** enabled to detect tampering
- Trail logs are stored securely in the S3 bucket
- CloudTrail events are also streamed to **CloudWatch Logs** for real-time visibility

### 4. **Monitoring and Alerts (CloudWatch)**
- CloudWatch **alarms**:
  - Alert when the main S3 bucket exceeds 10GB
  - Alert when any new object is created in the bucket
- Alarms trigger notifications via **Amazon SNS**
- **Email notifications** sent to a configured company address

### 5.  **Monthly Cost Budgeting**
- AWS Budgets configured to:
  - Monitor monthly spend ($100 limit)
  - Send alerts at 80% and 100% thresholds
- **Email notifications** keep billing transparent and under control

---

##  Project Structure

| File          | Description                                                   |
|---------------|---------------------------------------------------------------|
| `main.tf`     | All core infrastructure defined (S3, IAM, CloudTrail, etc.)   |


---

## KHOMOTSO MASHUPYE- CLOUD SOLUTIONS ARCHITECT
JUNE 2025

