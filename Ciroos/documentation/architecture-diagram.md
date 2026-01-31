# Ciroos Multi-Region EKS Architecture Diagram

## Architecture Overview

This document provides detailed specifications for creating the architecture diagram in Lucid Chart or any diagramming tool.

---

## Diagram Layout

### Title (Top Center)
**Text:** "Ciroos Demo: Multi-Region EKS with Cross-Region Communication and Splunk Observability"
**Style:** Large, bold, centered

---

## Layer 1: Internet & Entry Point

### Internet Cloud
- **Shape:** Cloud
- **Position:** Top center
- **Color:** Light blue (#dae8fc)
- **Label:** "Internet"

### AWS WAF
- **Shape:** Rectangle with rounded corners
- **Position:** Below Internet cloud
- **Color:** Light red (#f8cecc)
- **Label:**
  ```
  AWS WAF
  (Regional)
  ```

**Arrow:** Internet → WAF
- **Style:** Solid blue line, medium thickness
- **Label:** "HTTPS Traffic"

---

## Layer 2: Two AWS Regions (Side by Side)

### Region 1 (Left Side): us-east-1

#### Region Container
- **Shape:** Large rounded rectangle
- **Color:** Light yellow (#fff2cc)
- **Label:** "AWS Region: us-east-1 (C1 - Frontend)"
- **Border:** Medium thickness, yellow-brown

#### VPC C1 (Inside Region 1)
- **Shape:** Rounded rectangle (nested inside region)
- **Color:** Light purple (#e1d5e7)
- **Label:**
  ```
  VPC C1
  10.0.0.0/16
  ```

#### Application Load Balancer (Inside VPC C1)
- **Shape:** Rectangle
- **Position:** Top of VPC
- **Color:** Light green (#d5e8d4)
- **Label:**
  ```
  Application Load Balancer
  (Internet-facing)
  ab565512...elb.us-east-1...
  ```

#### EKS Cluster C1 (Inside VPC C1)
- **Shape:** Rounded rectangle
- **Color:** Light blue (#dae8fc)
- **Label:**
  ```
  EKS Cluster: petclinic-c1
  Kubernetes 1.30
  ```

#### Components Inside EKS C1:

1. **apm-test-app (Frontend Service)**
   - **Shape:** Rectangle
   - **Color:** Light yellow (#fff2cc)
   - **Label:**
     ```
     apm-test-app
     (Frontend Service)

     • Python Flask
     • OpenTelemetry instrumented
     • Calls C2 backend APIs
     • Distributed tracing
     ```

2. **Splunk OTel Collector**
   - **Shape:** Rectangle
   - **Color:** Light purple (#e1d5e7)
   - **Label:**
     ```
     Splunk OTel Collector

     Agent DaemonSet (2 pods)
     Cluster Receiver (1 pod)

     Version: 0.143.0
     ```

3. **RDS MySQL** (Below EKS cluster)
   - **Shape:** Rectangle
   - **Color:** Light green (#d5e8d4)
   - **Label:**
     ```
     RDS MySQL
     db.t3.micro

     Database for demo data
     ```

4. **Security Group** (Right side)
   - **Shape:** Dashed rectangle
   - **Color:** Light red (#f8cecc)
   - **Label:**
     ```
     Security Group
     Allows: HTTP/HTTPS
     from Internet
     ```

---

### Region 2 (Right Side): us-west-2

#### Region Container
- **Shape:** Large rounded rectangle
- **Color:** Light orange (#ffe6cc)
- **Label:** "AWS Region: us-west-2 (C2 - Backend)"
- **Border:** Medium thickness, orange-brown

#### VPC C2 (Inside Region 2)
- **Shape:** Rounded rectangle (nested inside region)
- **Color:** Light purple (#e1d5e7)
- **Label:**
  ```
  VPC C2
  10.1.0.0/16
  ```

#### Network Load Balancer (Inside VPC C2)
- **Shape:** Rectangle
- **Position:** Top of VPC
- **Color:** Light green (#d5e8d4)
- **Label:**
  ```
  Network Load Balancer
  (Internal Only)
  ac3dc550...elb.us-west-2...
  ```

#### EKS Cluster C2 (Inside VPC C2)
- **Shape:** Rounded rectangle
- **Color:** Light blue (#dae8fc)
- **Label:**
  ```
  EKS Cluster: petclinic-c2
  Kubernetes 1.30
  ```

#### Components Inside EKS C2:

1. **apm-backend-service (Backend Service)**
   - **Shape:** Rectangle
   - **Color:** Light yellow (#fff2cc)
   - **Label:**
     ```
     apm-backend-service
     (Backend Service)

     • Python Flask
     • OpenTelemetry instrumented
     • Inventory API
     • Shipping API
     • Payment processing
     • 20% simulated failures
     ```

2. **Splunk OTel Collector**
   - **Shape:** Rectangle
   - **Color:** Light purple (#e1d5e7)
   - **Label:**
     ```
     Splunk OTel Collector

     Agent DaemonSet (2 pods)
     Cluster Receiver (1 pod)

     Version: 0.143.0
     ```

3. **Security Group** (Right side)
   - **Shape:** Dashed rectangle
   - **Color:** Light red (#f8cecc)
   - **Label:**
     ```
     Security Group
     Allows: HTTP from C1 VPC only
     (10.0.0.0/16)
     ```

---

### VPC Peering (Between Regions)

- **Shape:** Rectangle
- **Position:** Between VPC C1 and VPC C2 (center)
- **Color:** Light gray (#f5f5f5)
- **Label:**
  ```
  VPC Peering Connection
  10.0.0.0/16 ↔ 10.1.0.0/16
  Private connectivity
  ```

---

## Layer 3: Splunk Observability Cloud (Bottom)

### Splunk Cloud Platform
- **Shape:** Large rounded rectangle
- **Position:** Bottom center, spanning width
- **Color:** Light blue (#b1ddf0)
- **Label:**
  ```
  Splunk Observability Cloud
  Realm: us1

  • Infrastructure Metrics (SignalFx)
  • APM Traces (OTLP)
  • Service Map
  • Kubernetes Navigator
  • Alerts & Dashboards
  ```

---

## Connections and Data Flows

### 1. Internet → WAF → ALB → Frontend App
- **Arrow:** Solid blue line, thick
- **Path:** Internet → WAF → ALB C1 → apm-test-app
- **Labels:** "HTTPS Traffic" → "Filtered"

### 2. Cross-Region API Calls (C1 → C2)
- **Arrow:** Thick orange dashed line (distinctive)
- **Path:** apm-test-app → VPC Peering → NLB C2 → apm-backend-service
- **Label:** "Cross-Region API Calls"
- **Style:** Dashed/dotted to indicate cross-region

### 3. Frontend App → Database
- **Arrow:** Thin green dashed line
- **Path:** apm-test-app → RDS MySQL
- **Style:** Thin, less prominent

### 4. Telemetry Collection (Apps → OTel Collectors)
- **Arrow:** Purple solid line, medium thickness
- **Paths:**
  - apm-test-app → Splunk OTel Collector (C1)
  - apm-backend-service → Splunk OTel Collector (C2)
- **Label:** "Traces & Metrics"

### 5. OTel Collectors → Splunk Cloud
- **Arrow:** Dark blue solid line, thick
- **Paths:**
  - Splunk OTel Collector (C1) → Splunk Observability Cloud
  - Splunk OTel Collector (C2) → Splunk Observability Cloud
- **Label:** "SignalFx + OTLP"

---

## Legend (Bottom Left)

### Legend Box
- **Shape:** Rounded rectangle
- **Color:** Light gray (#f5f5f5)
- **Title:** "Legend"

### Legend Items:

1. **Solid Blue Line** → "Public HTTP/HTTPS Traffic"
2. **Thick Orange Dashed Line** → "Cross-Region Private API Calls"
3. **Purple Line** → "Telemetry Data (Traces/Metrics)"
4. **Dark Blue Line** → "Splunk Observability Export"

---

## Key Features Box (Bottom Right)

### Features Box
- **Shape:** Rounded rectangle
- **Color:** Light green (#d5e8d4)
- **Title:** "Key Architecture Features"

### Features List:
```
✓ Dual-region EKS deployment (us-east-1 + us-west-2)
✓ VPC peering for private cross-region connectivity
✓ WAF protection on public ALB in C1
✓ Internal-only NLB in C2 (no public access)
✓ OpenTelemetry distributed tracing across regions
✓ Splunk Observability Cloud integration
✓ Infrastructure metrics + APM in single platform
✓ W3C TraceContext propagation for service map
```

---

## Color Palette Reference

| Component Type | Color | Hex Code |
|----------------|-------|----------|
| AWS Regions | Light yellow/orange | #fff2cc / #ffe6cc |
| VPCs | Light purple | #e1d5e7 |
| EKS Clusters | Light blue | #dae8fc |
| Load Balancers | Light green | #d5e8d4 |
| Applications | Light yellow | #fff2cc |
| OTel Collectors | Light purple | #e1d5e7 |
| Security Groups | Light red | #f8cecc |
| Splunk Cloud | Light blue | #b1ddf0 |
| VPC Peering | Light gray | #f5f5f5 |

---

## Critical Visual Elements to Emphasize

1. **The cross-region connection** (C1 → C2) should be the most visually prominent with thick orange dashed lines
2. **Two distinct regions** should be clearly separated with different background colors
3. **Security boundaries** shown with dashed boxes for security groups
4. **Data flow to Splunk** from both regions should converge at the bottom
5. **Public vs Private** distinction:
   - C1 ALB: Internet-facing (connected to Internet)
   - C2 NLB: Internal only (no Internet connection)

---

## Import Instructions

### For Lucid Chart:

1. **Option 1: Import draw.io file**
   - Go to Lucid Chart
   - File → Import → Browse
   - Select `architecture-diagram.drawio`
   - Lucid Chart may auto-convert the diagram

2. **Option 2: Manual Creation**
   - Use this document as a blueprint
   - Start with the two region containers (left and right)
   - Add VPCs inside each region
   - Add EKS clusters inside VPCs
   - Add components inside EKS clusters
   - Draw connections following the "Connections and Data Flows" section
   - Add legend and features boxes at the bottom

3. **Option 3: Use Lucid Chart AWS Architecture Library**
   - Lucid Chart → Shapes → AWS Architecture
   - Use official AWS shapes for:
     - VPC
     - EKS
     - Load Balancers
     - RDS
     - WAF
   - Add custom text and labels per this specification

---

## Diagram Dimensions

- **Recommended Canvas Size:** 1600px × 1200px (or equivalent in inches)
- **Region Containers:** ~40% of canvas width each
- **VPC Containers:** 90% of region container size
- **EKS Clusters:** 70% of VPC container size
- **Splunk Box:** Full width at bottom, 15% of canvas height

---

## Tips for Best Visual Impact

1. Use **consistent spacing** between components
2. Align all components on a grid for clean appearance
3. Make the **cross-region arrows** stand out with bright color and thickness
4. Use **shadows or depth** for the region containers to show layering
5. Add **icons** if available (AWS icons for services, Kubernetes logo for EKS)
6. Ensure **text is readable** at 100% zoom (minimum 10pt font)
7. Use **arrows with clear directionality** (pointed ends)
8. Add **small annotations** near critical connections explaining the protocol/port

---

## Verification Checklist

After creating the diagram, verify:

- [ ] Both regions clearly visible and labeled
- [ ] VPC peering connection shows private connectivity
- [ ] C1 has public ALB with WAF protection
- [ ] C2 has internal-only NLB (no public exposure)
- [ ] Cross-region API calls clearly shown (C1 → C2)
- [ ] Both OTel collectors send data to Splunk
- [ ] Legend explains all arrow types
- [ ] Key features box highlights main architectural points
- [ ] Color coding is consistent and meaningful
- [ ] All labels are readable and accurate
