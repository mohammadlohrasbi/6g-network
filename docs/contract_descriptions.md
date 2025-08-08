# توضیحات قراردادهای هوشمند پروژه 6G Fabric Network - بخش 1

این فایل توضیحات جامع قراردادهای 1 تا 9 (از 85 قرارداد هوشمند) را ارائه می‌دهد. هر قرارداد شامل وظیفه کلی، ساختار داده، توابع (با ورودی/خروجی و سناریوی استفاده)، و مثال دستورات invoke/query است.

## قراردادهای مرتبط با موقعیت

1. **LocationBasedAssignment**:

   - **وظیفه کلی**: تخصیص آنتن به کاربر یا دستگاه IoT بر اساس فاصله اقلیدسی.
   - **ساختار داده**:

     ```json
     {
       "entityID": "string",
       "antennaID": "string",
       "x": "string",
       "y": "string",
       "distance": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **AssignAntenna(entityID: string, antennaID: string, x: string, y: string) -&gt; error**:
       - **ورودی**: entityID، antennaID، مختصات x/y.
       - **خروجی**: nil یا خطا.
       - **سناریو**: تخصیص آنتن با محاسبه فاصله اقلیدسی.
     - **QueryAsset(entityID: string) -&gt; Assignment**:
       - **خروجی**: JSON ساختار Assignment.
       - **سناریو**: بررسی تخصیص.
     - **QueryAllAssets() -&gt; \[\]Assignment**:
       - **خروجی**: لیست تمام تخصیص‌ها.
       - **سناریو**: نمایش برای Network Map.
     - **ValidateAssignmentDistance(entityID: string, maxDistance: string) -&gt; bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی فاصله.
   - **مثال دستورات**:

     ```bash
     peer chaincode invoke -C GeneralOperationsChannel -n LocationBasedAssignment -c '{"function":"AssignAntenna","Args":["user1","Antenna1","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C GeneralOperationsChannel -n LocationBasedAssignment -c '{"function":"QueryAsset","Args":["user1"]}'
     ```

2. **LocationBasedConnection**:

   - **وظیفه کلی**: مدیریت اتصال کاربر یا دستگاه به آنتن بر اساس فاصله.
   - **ساختار داده**:

     ```json
     {
       "entityID": "string",
       "antennaID": "string",
       "x": "string",
       "y": "string",
       "distance": "string",
       "status": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **ConnectEntity(entityID: string, antennaID: string, x: string, y: string) -&gt; error**:
       - **ورودی**: entityID، antennaID، x/y.
       - **خروجی**: nil یا خطا.
       - **سناریو**: اتصال با محاسبه فاصله.
     - **DisconnectEntity(entityID: string) -&gt; error**:
       - **ورودی**: entityID.
       - **خروجی**: nil یا خطا.
       - **سناریو**: قطع اتصال.
     - **QueryAsset(entityID: string) -&gt; Connection**:
       - **خروجی**: JSON ساختار Connection.
       - **سناریو**: بررسی اتصال.
     - **QueryAllAssets() -&gt; \[\]Connection**:
       - **خروجی**: لیست تمام اتصال‌ها.
       - **سناریو**: نمایش برای Network Map.
     - **ValidateConnectionDistance(entityID: string, maxDistance: string) -&gt; bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی فاصله.
   - **مثال دستورات**:

     ```bash
     peer chaincode invoke -C ConnectivityChannel -n LocationBasedConnection -c '{"function":"ConnectEntity","Args":["user1","Antenna1","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode invoke -C ConnectivityChannel -n LocationBasedConnection -c '{"function":"DisconnectEntity","Args":["user1"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C ConnectivityChannel -n LocationBasedConnection -c '{"function":"QueryAsset","Args":["user1"]}'
     ```

3. **LocationBasedBandwidth**:

   - **وظیفه کلی**: تخصیص پهنای باند به کاربر یا دستگاه IoT بر اساس فاصله.
   - **ساختار داده**:

     ```json
     {
       "entityID": "string",
       "antennaID": "string",
       "bandwidth": "string",
       "x": "string",
       "y": "string",
       "distance": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **AllocateBandwidth(entityID: string, antennaID: string, bandwidth: string, x: string, y: string) -&gt; error**:
       - **ورودی**: entityID، antennaID، bandwidth، x/y.
       - **خروجی**: nil یا خطا.
       - **سناریو**: تخصیص پهنای باند.
     - **UpdateBandwidth(entityID: string, newBandwidth: string) -&gt; error**:
       - **ورودی**: entityID، newBandwidth.
       - **خروجی**: nil یا خطا.
       - **سناریو**: به‌روزرسانی پهنای باند.
     - **QueryAsset(entityID: string) -&gt; BandwidthAllocation**:
       - **خروجی**: JSON ساختار BandwidthAllocation.
       - **سناریو**: بررسی تخصیص.
     - **QueryAllAssets() -&gt; \[\]BandwidthAllocation**:
       - **خروجی**: لیست تمام تخصیص‌ها.
       - **سناریو**: نمایش برای Network Map.
     - **ValidateBandwidthDistance(entityID: string, maxDistance: string) -&gt; bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی فاصله.
   - **مثال دستورات**:

     ```bash
     peer chaincode invoke -C ResourceChannel -n LocationBasedBandwidth -c '{"function":"AllocateBandwidth","Args":["user1","Antenna1","100Mbps","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode invoke -C ResourceChannel -n LocationBasedBandwidth -c '{"function":"UpdateBandwidth","Args":["user1","200Mbps"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C ResourceChannel -n LocationBasedBandwidth -c '{"function":"QueryAsset","Args":["user1"]}'
     ```

4. **LocationBasedQoS**:

   - **وظیفه کلی**: تخصیص سطح کیفیت خدمات (QoS) به کاربر یا دستگاه IoT بر اساس فاصله.
   - **ساختار داده**:

     ```json
     {
       "entityID": "string",
       "antennaID": "string",
       "qosLevel": "string",
       "x": "string",
       "y": "string",
       "distance": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **AllocateQoS(entityID: string, antennaID: string, qosLevel: string, x: string, y: string) -&gt; error**:
       - **ورودی**: entityID، antennaID، qosLevel، x/y.
       - **خروجی**: nil یا خطا.
       - **سناریو**: تخصیص سطح QoS.
     - **UpdateQoS(entityID: string, newQoSLevel: string) -&gt; error**:
       - **ورودی**: entityID، newQoSLevel.
       - **خروجی**: nil یا خطا.
       - **سناریو**: به‌روزرسانی سطح QoS.
     - **QueryAsset(entityID: string) -&gt; QoSAllocation**:
       - **خروجی**: JSON ساختار QoSAllocation.
       - **سناریو**: بررسی تخصیص.
     - **QueryAllAssets() -&gt; \[\]QoSAllocation**:
       - **خروجی**: لیست تمام تخصیص‌ها.
       - **سناریو**: نمایش برای Network Map.
     - **ValidateQoSDistance(entityID: string, maxDistance: string) -&gt; bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی فاصله.
   - **مثال دستورات**:

     ```bash
     peer chaincode invoke -C ResourceChannel -n LocationBasedQoS -c '{"function":"AllocateQoS","Args":["user1","Antenna1","High","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode invoke -C ResourceChannel -n LocationBasedQoS -c '{"function":"UpdateQoS","Args":["user1","Medium"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C ResourceChannel -n LocationBasedQoS -c '{"function":"QueryAsset","Args":["user1"]}'
     ```

5. **LocationBasedPriority**:

   - **وظیفه کلی**: تخصیص اولویت به کاربر یا دستگاه IoT بر اساس فاصله.
   - **ساختار داده**:

     ```json
     {
       "entityID": "string",
       "priority": "string",
       "x": "string",
       "y": "string",
       "distance": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **AssignPriority(entityID: string, priority: string, x: string, y: string) -&gt; error**:
       - **ورودی**: entityID، priority، x/y.
       - **خروجی**: nil یا خطا.
       - **سناریو**: تخصیص اولویت.
     - **UpdatePriority(entityID: string, newPriority: string) -&gt; error**:
       - **ورودی**: entityID، newPriority.
       - **خروجی**: nil یا خطا.
       - **سناریو**: به‌روزرسانی اولویت.
     - **QueryAsset(entityID: string) -&gt; PriorityAllocation**:
       - **خروجی**: JSON ساختار PriorityAllocation.
       - **سناریو**: بررسی تخصیص.
     - **QueryAllAssets() -&gt; \[\]PriorityAllocation**:
       - **خروجی**: لیست تمام تخصیص‌ها.
       - **سناریو**: نمایش برای Network Map.
     - **ValidatePriorityDistance(entityID: string, maxDistance: string) -&gt; bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی فاصله.
   - **مثال دستورات**:

     ```bash
     peer chaincode invoke -C PolicyChannel -n LocationBasedPriority -c '{"function":"AssignPriority","Args":["user1","High","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode invoke -C PolicyChannel -n LocationBasedPriority -c '{"function":"UpdatePriority","Args":["user1","Low"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C PolicyChannel -n LocationBasedPriority -c '{"function":"QueryAsset","Args":["user1"]}'
     ```

6. **LocationBasedStatus**:

   - **وظیفه کلی**: ثبت و به‌روزرسانی وضعیت کاربر یا دستگاه IoT بر اساس فاصله.
   - **ساختار داده**:

     ```json
     {
       "entityID": "string",
       "status": "string",
       "x": "string",
       "y": "string",
       "distance": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **UpdateStatus(entityID: string, status: string, x: string, y: string) -&gt; error**:
       - **ورودی**: entityID، status، x/y.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت وضعیت.
     - **QueryAsset(entityID: string) -&gt; StatusRecord**:
       - **خروجی**: JSON ساختار StatusRecord.
       - **سناریو**: بررسی وضعیت.
     - **QueryAllAssets() -&gt; \[\]StatusRecord**:
       - **خروجی**: لیست تمام وضعیت‌ها.
       - **سناریو**: نمایش برای ممیزی.
     - **ValidateStatusDistance(entityID: string, maxDistance: string) -&gt; bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی فاصله.
   - **مثال دستورات**:

     ```bash
     peer chaincode invoke -C AuditChannel -n LocationBasedStatus -c '{"function":"UpdateStatus","Args":["user1","Active","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C AuditChannel -n LocationBasedStatus -c '{"function":"QueryAsset","Args":["user1"]}'
     ```

7. **LocationBasedFault**:

   - **وظیفه کلی**: ثبت خطاها یا خرابی‌های کاربر یا دستگاه IoT بر اساس فاصله.
   - **ساختار داده**:

     ```json
     {
       "entityID": "string",
       "faultType": "string",
       "x": "string",
       "y": "string",
       "distance": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **ReportFault(entityID: string, faultType: string, x: string, y: string) -&gt; error**:
       - **ورودی**: entityID، faultType، x/y.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت خطا.
     - **QueryAsset(entityID: string) -&gt; FaultRecord**:
       - **خروجی**: JSON ساختار FaultRecord.
       - **سناریو**: بررسی خطا.
     - **QueryAllAssets() -&gt; \[\]FaultRecord**:
       - **خروجی**: لیست تمام خطاها.
       - **سناریو**: نمایش برای ممیزی.
     - **ValidateFaultDistance(entityID: string, maxDistance: string) -&gt; bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی فاصله.
   - **مثال دستورات**:

     ```bash
     peer chaincode invoke -C AuditChannel -n LocationBasedFault -c '{"function":"ReportFault","Args":["user1","SignalLoss","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C AuditChannel -n LocationBasedFault -c '{"function":"QueryAsset","Args":["user1"]}'
     ```

8. **LocationBasedTraffic**:

   - **وظیفه کلی**: ثبت ترافیک شبکه کاربر یا دستگاه IoT بر اساس فاصله.
   - **ساختار داده**:

     ```json
     {
       "entityID": "string",
       "traffic": "string",
       "x": "string",
       "y": "string",
       "distance": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **RecordTraffic(entityID: string, traffic: string, x: string, y: string) -&gt; error**:
       - **ورودی**: entityID، traffic، x/y.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت ترافیک.
     - **QueryAsset(entityID: string) -&gt; TrafficRecord**:
       - **خروجی**: JSON ساختار TrafficRecord.
       - **سناریو**: بررسی ترافیک.
     - **QueryAllAssets() -&gt; \[\]TrafficRecord**:
       - **خروجی**: لیست تمام ترافیک‌ها.
       - **سناریو**: نمایش برای Network Map.
     - **ValidateTrafficDistance(entityID: string, maxDistance: string) -&gt; bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی فاصله.
   - **مثال دستورات**:

     ```bash
     peer chaincode invoke -C PerformanceChannel -n LocationBasedTraffic -c '{"function":"RecordTraffic","Args":["user1","500MB","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C PerformanceChannel -n LocationBasedTraffic -c '{"function":"QueryAsset","Args":["user1"]}'
     ```

9. **LocationBasedLatency**:

   - **وظیفه کلی**: ثبت تأخیر شبکه کاربر یا دستگاه IoT بر اساس فاصله.
   - **ساختار داده**:

     ```json
     {
       "entityID": "string",
       "latency": "string",
       "x": "string",
       "y": "string",
       "distance": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **RecordLatency(entityID: string, latency: string, x: string, y: string) -&gt; error**:
       - **ورودی**: entityID، latency، x/y.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت تأخیر.
     - **QueryAsset(entityID: string) -&gt; LatencyRecord**:
       - **خروجی**: JSON ساختار LatencyRecord.
       - **سناریو**: بررسی تأخیر.
     - **QueryAllAssets() -&gt; \[\]LatencyRecord**:
       - **خروجی**: لیست تمام تأخیرها.
       - **سناریو**: نمایش برای Network Map.
     - **ValidateLatencyDistance(entityID: string, maxDistance: string) -&gt; bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی فاصله.
   - **مثال دستورات**:

     ```bash
     peer chaincode invoke -C PerformanceChannel -n LocationBasedLatency -c '{"function":"RecordLatency","Args":["user1","50ms","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C PerformanceChannel -n LocationBasedLatency -c '{"function":"QueryAsset","Args":["user1"]}'
     ```
     # توضیحات قراردادهای هوشمند پروژه 6G Fabric Network - بخش 2

این فایل توضیحات جامع قراردادهای 10 تا 17 (از 85 قرارداد هوشمند) را ارائه می‌دهد. هر قرارداد شامل وظیفه کلی، ساختار داده، توابع (با ورودی/خروجی و سناریوی استفاده)، و مثال دستورات invoke/query است.

## قراردادهای مرتبط با موقعیت

10. **LocationBasedEnergy**:
   - **وظیفه کلی**: ثبت مصرف انرژی کاربر یا دستگاه IoT بر اساس فاصله.
   - **ساختار داده**:
     ```json
     {
       "entityID": "string",
       "energy": "string",
       "x": "string",
       "y": "string",
       "distance": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **RecordEnergy(entityID: string, energy: string, x: string, y: string) -> error**:
       - **ورودی**: entityID، energy، x/y.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت مصرف انرژی.
     - **QueryAsset(entityID: string) -> EnergyRecord**:
       - **خروجی**: JSON ساختار EnergyRecord.
       - **سناریو**: بررسی مصرف انرژی.
     - **QueryAllAssets() -> []EnergyRecord**:
       - **خروجی**: لیست تمام رکوردهای انرژی.
       - **سناریو**: نمایش برای ممیزی.
     - **ValidateEnergyDistance(entityID: string, maxDistance: string) -> bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی فاصله.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C PerformanceChannel -n LocationBasedEnergy -c '{"function":"RecordEnergy","Args":["user1","100W","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C PerformanceChannel -n LocationBasedEnergy -c '{"function":"QueryAsset","Args":["user1"]}'
     ```

11. **LocationBasedRoaming**:
   - **وظیفه کلی**: مدیریت رومینگ کاربر یا دستگاه IoT به آنتن‌های مختلف بر اساس فاصله.
   - **ساختار داده**:
     ```json
     {
       "entityID": "string",
       "antennaID": "string",
       "x": "string",
       "y": "string",
       "distance": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **PerformRoaming(entityID: string, antennaID: string, x: string, y: string) -> error**:
       - **ورودی**: entityID، antennaID، x/y.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت رومینگ.
     - **QueryAsset(entityID: string) -> RoamingRecord**:
       - **خروجی**: JSON ساختار RoamingRecord.
       - **سناریو**: بررسی رومینگ.
     - **QueryAllAssets() -> []RoamingRecord**:
       - **خروجی**: لیست تمام رومینگ‌ها.
       - **سناریو**: نمایش برای Network Map.
     - **ValidateRoamingDistance(entityID: string, maxDistance: string) -> bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی فاصله.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C ConnectivityChannel -n LocationBasedRoaming -c '{"function":"PerformRoaming","Args":["user1","Antenna2","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C ConnectivityChannel -n LocationBasedRoaming -c '{"function":"QueryAsset","Args":["user1"]}'
     ```

12. **LocationBasedSignalStrength**:
   - **وظیفه کلی**: ثبت قدرت سیگنال کاربر یا دستگاه IoT بر اساس فاصله.
   - **ساختار داده**:
     ```json
     {
       "entityID": "string",
       "signal": "string",
       "x": "string",
       "y": "string",
       "distance": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **RecordSignalStrength(entityID: string, signal: string, x: string, y: string) -> error**:
       - **ورودی**: entityID، signal، x/y.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت قدرت سیگنال.
     - **QueryAsset(entityID: string) -> SignalStrengthRecord**:
       - **خروجی**: JSON ساختار SignalStrengthRecord.
       - **سناریو**: بررسی قدرت سیگنال.
     - **QueryAllAssets() -> []SignalStrengthRecord**:
       - **خروجی**: لیست تمام رکوردهای سیگنال.
       - **سناریو**: نمایش برای Network Map.
     - **ValidateSignalDistance(entityID: string, maxDistance: string) -> bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی فاصله.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C PerformanceChannel -n LocationBasedSignalStrength -c '{"function":"RecordSignalStrength","Args":["user1","-70dBm","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C PerformanceChannel -n LocationBasedSignalStrength -c '{"function":"QueryAsset","Args":["user1"]}'
     ```

13. **LocationBasedCoverage**:
   - **وظیفه کلی**: ثبت میزان پوشش شبکه برای کاربر یا دستگاه IoT بر اساس فاصله.
   - **ساختار داده**:
     ```json
     {
       "entityID": "string",
       "coverage": "string",
       "x": "string",
       "y": "string",
       "distance": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **RecordCoverage(entityID: string, coverage: string, x: string, y: string) -> error**:
       - **ورودی**: entityID، coverage، x/y.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت پوشش شبکه.
     - **QueryAsset(entityID: string) -> CoverageRecord**:
       - **خروجی**: JSON ساختار CoverageRecord.
       - **سناریو**: بررسی پوشش.
     - **QueryAllAssets() -> []CoverageRecord**:
       - **خروجی**: لیست تمام رکوردهای پوشش.
       - **سناریو**: نمایش برای Network Map.
     - **ValidateCoverageDistance(entityID: string, maxDistance: string) -> bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی فاصله.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C PerformanceChannel -n LocationBasedCoverage -c '{"function":"RecordCoverage","Args":["user1","95%","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C PerformanceChannel -n LocationBasedCoverage -c '{"function":"QueryAsset","Args":["user1"]}'
     ```

14. **LocationBasedInterference**:
   - **وظیفه کلی**: ثبت سطح تداخل سیگنال برای کاربر یا دستگاه IoT بر اساس فاصله.
   - **ساختار داده**:
     ```json
     {
       "entityID": "string",
       "interferenceLevel": "string",
       "x": "string",
       "y": "string",
       "distance": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **RecordInterference(entityID: string, interferenceLevel: string, x: string, y: string) -> error**:
       - **ورودی**: entityID، interferenceLevel، x/y.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت سطح تداخل.
     - **QueryAsset(entityID: string) -> InterferenceRecord**:
       - **خروجی**: JSON ساختار InterferenceRecord.
       - **سناریو**: بررسی تداخل.
     - **QueryAllAssets() -> []InterferenceRecord**:
       - **خروجی**: لیست تمام رکوردهای تداخل.
       - **سناریو**: نمایش برای ممیزی.
     - **ValidateInterferenceDistance(entityID: string, maxDistance: string) -> bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی فاصله.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C PerformanceChannel -n LocationBasedInterference -c '{"function":"RecordInterference","Args":["user1","Low","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C PerformanceChannel -n LocationBasedInterference -c '{"function":"QueryAsset","Args":["user1"]}'
     ```

15. **LocationBasedResourceAllocation**:
   - **وظیفه کلی**: تخصیص منابع (مانند پهنای باند یا توان) به کاربر یا دستگاه IoT بر اساس فاصله.
   - **ساختار داده**:
     ```json
     {
       "entityID": "string",
       "resourceID": "string",
       "amount": "string",
       "x": "string",
       "y": "string",
       "distance": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **AllocateResource(entityID: string, resourceID: string, amount: string, x: string, y: string) -> error**:
       - **ورودی**: entityID، resourceID، amount، x/y.
       - **خروجی**: nil یا خطا.
       - **سناریو**: تخصیص منبع.
     - **QueryAsset(entityID: string) -> ResourceAllocation**:
       - **خروجی**: JSON ساختار ResourceAllocation.
       - **سناریو**: بررسی تخصیص.
     - **QueryAllAssets() -> []ResourceAllocation**:
       - **خروجی**: لیست تمام تخصیص‌ها.
       - **سناریو**: نمایش برای Network Map.
     - **ValidateResourceDistance(entityID: string, maxDistance: string) -> bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی فاصله.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C ResourceChannel -n LocationBasedResourceAllocation -c '{"function":"AllocateResource","Args":["user1","Bandwidth","100Mbps","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C ResourceChannel -n LocationBasedResourceAllocation -c '{"function":"QueryAsset","Args":["user1"]}'
     ```

16. **LocationBasedNetworkLoad**:
   - **وظیفه کلی**: ثبت بار شبکه برای کاربر یا دستگاه IoT بر اساس فاصله.
   - **ساختار داده**:
     ```json
     {
       "entityID": "string",
       "load": "string",
       "x": "string",
       "y": "string",
       "distance": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **RecordNetworkLoad(entityID: string, load: string, x: string, y: string) -> error**:
       - **ورودی**: entityID، load، x/y.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت بار شبکه.
     - **QueryAsset(entityID: string) -> NetworkLoadRecord**:
       - **خروجی**: JSON ساختار NetworkLoadRecord.
       - **سناریو**: بررسی بار شبکه.
     - **QueryAllAssets() -> []NetworkLoadRecord**:
       - **خروجی**: لیست تمام رکوردهای بار شبکه.
       - **سناریو**: نمایش برای ممیزی.
     - **ValidateLoadDistance(entityID: string, maxDistance: string) -> bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی فاصله.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C PerformanceChannel -n LocationBasedNetworkLoad -c '{"function":"RecordNetworkLoad","Args":["user1","High","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C PerformanceChannel -n LocationBasedNetworkLoad -c '{"function":"QueryAsset","Args":["user1"]}'
     ```
     # توضیحات قراردادهای هوشمند پروژه 6G Fabric Network - بخش 3

این فایل توضیحات جامع قراردادهای 18 تا 26 (از 85 قرارداد هوشمند) را ارائه می‌دهد. هر قرارداد شامل وظیفه کلی، ساختار داده، توابع (با ورودی/خروجی و سناریوی استفاده)، و مثال دستورات invoke/query است.

## قراردادهای مرتبط با موقعیت

18. **LocationBasedCongestion**:
   - **وظیفه کلی**: ثبت سطح تراکم شبکه برای کاربر یا دستگاه IoT بر اساس فاصله.
   - **ساختار داده**:
     ```json
     {
       "entityID": "string",
       "congestion": "string",
       "x": "string",
       "y": "string",
       "distance": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **RecordCongestion(entityID: string, congestion: string, x: string, y: string) -> error**:
       - **ورودی**: entityID، congestion، x/y.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت سطح تراکم.
     - **QueryAsset(entityID: string) -> CongestionRecord**:
       - **خروجی**: JSON ساختار CongestionRecord.
       - **سناریو**: بررسی تراکم.
     - **QueryAllAssets() -> []CongestionRecord**:
       - **خروجی**: لیست تمام رکوردهای تراکم.
       - **سناریو**: نمایش برای ممیزی.
     - **ValidateCongestionDistance(entityID: string, maxDistance: string) -> bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی فاصله.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C PerformanceChannel -n LocationBasedCongestion -c '{"function":"RecordCongestion","Args":["user1","High","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C PerformanceChannel -n LocationBasedCongestion -c '{"function":"QueryAsset","Args":["user1"]}'
     ```

19. **LocationBasedDynamicRouting**:
   - **وظیفه کلی**: تنظیم مسیرهای پویا برای کاربر یا دستگاه IoT بر اساس فاصله.
   - **ساختار داده**:
     ```json
     {
       "entityID": "string",
       "route": "string",
       "x": "string",
       "y": "string",
       "distance": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **SetRoute(entityID: string, route: string, x: string, y: string) -> error**:
       - **ورودی**: entityID، route، x/y.
       - **خروجی**: nil یا خطا.
       - **سناریو**: تنظیم مسیر پویا.
     - **QueryAsset(entityID: string) -> RoutingRecord**:
       - **خروجی**: JSON ساختار RoutingRecord.
       - **سناریو**: بررسی مسیر.
     - **QueryAllAssets() -> []RoutingRecord**:
       - **خروجی**: لیست تمام مسیرها.
       - **سناریو**: نمایش برای Network Map.
     - **ValidateRouteDistance(entityID: string, maxDistance: string) -> bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی فاصله.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C ConnectivityChannel -n LocationBasedDynamicRouting -c '{"function":"SetRoute","Args":["user1","RouteA","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C ConnectivityChannel -n LocationBasedDynamicRouting -c '{"function":"QueryAsset","Args":["user1"]}'
     ```

20. **LocationBasedAntennaConfig**:
   - **وظیفه کلی**: مدیریت تنظیمات آنتن‌ها بر اساس موقعیت.
   - **ساختار داده**:
     ```json
     {
       "antennaID": "string",
       "config": "string",
       "x": "string",
       "y": "string",
       "distance": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **SetAntennaConfig(antennaID: string, config: string, x: string, y: string) -> error**:
       - **ورودی**: antennaID، config، x/y.
       - **خروجی**: nil یا خطا.
       - **سناریو**: تنظیم پیکربندی آنتن.
     - **QueryAsset(antennaID: string) -> AntennaConfig**:
       - **خروجی**: JSON ساختار AntennaConfig.
       - **سناریو**: بررسی پیکربندی.
     - **QueryAllAssets() -> []AntennaConfig**:
       - **خروجی**: لیست تمام پیکربندی‌ها.
       - **سناریو**: نمایش برای ممیزی.
     - **ValidateConfigDistance(antennaID: string, maxDistance: string) -> bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی فاصله.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C ResourceChannel -n LocationBasedAntennaConfig -c '{"function":"SetAntennaConfig","Args":["Antenna1","Config1","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C ResourceChannel -n LocationBasedAntennaConfig -c '{"function":"QueryAsset","Args":["Antenna1"]}'
     ```

21. **LocationBasedSignalQuality**:
   - **وظیفه کلی**: ثبت کیفیت سیگنال برای کاربر یا دستگاه IoT بر اساس فاصله.
   - **ساختار داده**:
     ```json
     {
       "entityID": "string",
       "signalQuality": "string",
       "x": "string",
       "y": "string",
       "distance": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **RecordSignalQuality(entityID: string, signalQuality: string, x: string, y: string) -> error**:
       - **ورودی**: entityID، signalQuality، x/y.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت کیفیت سیگنال.
     - **QueryAsset(entityID: string) -> SignalQualityRecord**:
       - **خروجی**: JSON ساختار SignalQualityRecord.
       - **سناریو**: بررسی کیفیت سیگنال.
     - **QueryAllAssets() -> []SignalQualityRecord**:
       - **خروجی**: لیست تمام رکوردهای کیفیت.
       - **سناریو**: نمایش برای Network Map.
     - **ValidateSignalQualityDistance(entityID: string, maxDistance: string) -> bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی فاصله.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C PerformanceChannel -n LocationBasedSignalQuality -c '{"function":"RecordSignalQuality","Args":["user1","Good","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C PerformanceChannel -n LocationBasedSignalQuality -c '{"function":"QueryAsset","Args":["user1"]}'
     ```

22. **LocationBasedNetworkHealth**:
   - **وظیفه کلی**: ثبت سلامت شبکه برای کاربر یا دستگاه IoT بر اساس فاصله.
   - **ساختار داده**:
     ```json
     {
       "entityID": "string",
       "healthStatus": "string",
       "x": "string",
       "y": "string",
       "distance": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **RecordNetworkHealth(entityID: string, healthStatus: string, x: string, y: string) -> error**:
       - **ورودی**: entityID، healthStatus، x/y.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت سلامت شبکه.
     - **QueryAsset(entityID: string) -> NetworkHealthRecord**:
       - **خروجی**: JSON ساختار NetworkHealthRecord.
       - **سناریو**: بررسی سلامت شبکه.
     - **QueryAllAssets() -> []NetworkHealthRecord**:
       - **خروجی**: لیست تمام رکوردهای سلامت.
       - **سناریو**: نمایش برای ممیزی.
     - **ValidateHealthDistance(entityID: string, maxDistance: string) -> bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی فاصله.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C PerformanceChannel -n LocationBasedNetworkHealth -c '{"function":"RecordNetworkHealth","Args":["user1","Stable","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C PerformanceChannel -n LocationBasedNetworkHealth -c '{"function":"QueryAsset","Args":["user1"]}'
     ```

23. **LocationBasedPowerManagement**:
   - **وظیفه کلی**: مدیریت سطح توان کاربر یا دستگاه IoT بر اساس فاصله.
   - **ساختار داده**:
     ```json
     {
       "entityID": "string",
       "powerLevel": "string",
       "x": "string",
       "y": "string",
       "distance": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **SetPowerLevel(entityID: string, powerLevel: string, x: string, y: string) -> error**:
       - **ورودی**: entityID، powerLevel، x/y.
       - **خروجی**: nil یا خطا.
       - **سناریو**: تنظیم سطح توان.
     - **QueryAsset(entityID: string) -> PowerRecord**:
       - **خروجی**: JSON ساختار PowerRecord.
       - **سناریو**: بررسی سطح توان.
     - **QueryAllAssets() -> []PowerRecord**:
       - **خروجی**: لیست تمام رکوردهای توان.
       - **سناریو**: نمایش برای ممیزی.
     - **ValidatePowerDistance(entityID: string, maxDistance: string) -> bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی فاصله.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C ResourceChannel -n LocationBasedPowerManagement -c '{"function":"SetPowerLevel","Args":["user1","50dBm","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C ResourceChannel -n LocationBasedPowerManagement -c '{"function":"QueryAsset","Args":["user1"]}'
     ```

24. **LocationBasedChannelAllocation**:
   - **وظیفه کلی**: تخصیص کانال ارتباطی به کاربر یا دستگاه IoT بر اساس فاصله.
   - **ساختار داده**:
     ```json
     {
       "entityID": "string",
       "channelID": "string",
       "x": "string",
       "y": "string",
       "distance": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **AllocateChannel(entityID: string, channelID: string, x: string, y: string) -> error**:
       - **ورودی**: entityID، channelID، x/y.
       - **خروجی**: nil یا خطا.
       - **سناریو**: تخصیص کانال.
     - **QueryAsset(entityID: string) -> ChannelAllocation**:
       - **خروجی**: JSON ساختار ChannelAllocation.
       - **سناریو**: بررسی تخصیص کانال.
     - **QueryAllAssets() -> []ChannelAllocation**:
       - **خروجی**: لیست تمام تخصیص‌های کانال.
       - **سناریو**: نمایش برای Network Map.
     - **ValidateChannelDistance(entityID: string, maxDistance: string) -> bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی فاصله.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C ResourceChannel -n LocationBasedChannelAllocation -c '{"function":"AllocateChannel","Args":["user1","Channel1","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C ResourceChannel -n LocationBasedChannelAllocation -c '{"function":"QueryAsset","Args":["user1"]}'
     ```

25. **LocationBasedSessionManagement**:
   - **وظیفه کلی**: مدیریت جلسات کاربر یا دستگاه IoT بر اساس فاصله.
   - **ساختار داده**:
     ```json
     {
       "entityID": "string",
       "sessionID": "string",
       "x": "string",
       "y": "string",
       "distance": "string",
       "status": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **StartSession(entityID: string, sessionID: string, x: string, y: string) -> error**:
       - **ورودی**: entityID، sessionID، x/y.
       - **خروجی**: nil یا خطا.
       - **سناریو**: شروع جلسه.
     - **EndSession(entityID: string) -> error**:
       - **ورودی**: entityID.
       - **خروجی**: nil یا خطا.
       - **سناریو**: پایان جلسه.
     - **QueryAsset(entityID: string) -> SessionRecord**:
       - **خروجی**: JSON ساختار SessionRecord.
       - **سناریو**: بررسی جلسه.
     - **QueryAllAssets() -> []SessionRecord**:
       - **خروجی**: لیست تمام جلسات.
       - **سناریو**: نمایش برای ممیزی.
     - **ValidateSessionDistance(entityID: string, maxDistance: string) -> bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی فاصله.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C SessionChannel -n LocationBasedSessionManagement -c '{"function":"StartSession","Args":["user1","Session1","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode invoke -C SessionChannel -n LocationBasedSessionManagement -c '{"function":"EndSession","Args":["user1"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C SessionChannel -n LocationBasedSessionManagement -c '{"function":"QueryAsset","Args":["user1"]}'
     ```

26. **LocationBasedIoTConnection**:
   - **وظیفه کلی**: مدیریت اتصال دستگاه‌های IoT به آنتن‌ها بر اساس فاصله.
   - **ساختار داده**:
     ```json
     {
       "deviceID": "string",
       "antennaID": "string",
       "x": "string",
       "y": "string",
       "distance": "string",
       "status": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **ConnectIoTDevice(deviceID: string, antennaID: string, x: string, y: string) -> error**:
       - **ورودی**: deviceID، antennaID، x/y.
       - **خروجی**: nil یا خطا.
       - **سناریو**: اتصال دستگاه IoT.
     - **DisconnectIoTDevice(deviceID: string) -> error**:
       - **ورودی**: deviceID.
       - **خروجی**: nil یا خطا.
       - **سناریو**: قطع اتصال دستگاه.
     - **QueryAsset(deviceID: string) -> IoTConnection**:
       - **خروجی**: JSON ساختار IoTConnection.
       - **سناریو**: بررسی اتصال.
     - **QueryAllAssets() -> []IoTConnection**:
       - **خروجی**: لیست تمام اتصال‌ها.
       - **سناریو**: نمایش برای Network Map.
     - **ValidateIoTConnectionDistance(deviceID: string, maxDistance: string) -> bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی فاصله.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C IoTChannel -n LocationBasedIoTConnection -c '{"function":"ConnectIoTDevice","Args":["iot1","Antenna1","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode invoke -C IoTChannel -n LocationBasedIoTConnection -c '{"function":"DisconnectIoTDevice","Args":["iot1"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C IoTChannel -n LocationBasedIoTConnection -c '{"function":"QueryAsset","Args":["iot1"]}'
     ```
     # توضیحات قراردادهای هوشمند پروژه 6G Fabric Network - بخش 4

این فایل توضیحات جامع قراردادهای 27 تا 34 (از 85 قرارداد هوشمند) را ارائه می‌دهد. هر قرارداد شامل وظیفه کلی، ساختار داده، توابع (با ورودی/خروجی و سناریوی استفاده)، و مثال دستورات invoke/query است.

## قراردادهای مرتبط با موقعیت

27. **LocationBasedIoTBandwidth**:
   - **وظیفه کلی**: تخصیص پهنای باند به دستگاه‌های IoT بر اساس فاصله.
   - **ساختار داده**:
     ```json
     {
       "deviceID": "string",
       "antennaID": "string",
       "bandwidth": "string",
       "x": "string",
       "y": "string",
       "distance": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **AllocateIoTBandwidth(deviceID: string, antennaID: string, bandwidth: string, x: string, y: string) -> error**:
       - **ورودی**: deviceID، antennaID، bandwidth، x/y.
       - **خروجی**: nil یا خطا.
       - **سناریو**: تخصیص پهنای باند به دستگاه IoT.
     - **UpdateIoTBandwidth(deviceID: string, newBandwidth: string) -> error**:
       - **ورودی**: deviceID، newBandwidth.
       - **خروجی**: nil یا خطا.
       - **سناریو**: به‌روزرسانی پهنای باند.
     - **QueryAsset(deviceID: string) -> IoTBandwidthAllocation**:
       - **خروجی**: JSON ساختار IoTBandwidthAllocation.
       - **سناریو**: بررسی تخصیص پهنای باند.
     - **QueryAllAssets() -> []IoTBandwidthAllocation**:
       - **خروجی**: لیست تمام تخصیص‌های پهنای باند.
       - **سناریو**: نمایش برای Network Map.
     - **ValidateIoTBandwidthDistance(deviceID: string, maxDistance: string) -> bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی فاصله.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C IoTChannel -n LocationBasedIoTBandwidth -c '{"function":"AllocateIoTBandwidth","Args":["iot1","Antenna1","50Mbps","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode invoke -C IoTChannel -n LocationBasedIoTBandwidth -c '{"function":"UpdateIoTBandwidth","Args":["iot1","100Mbps"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C IoTChannel -n LocationBasedIoTBandwidth -c '{"function":"QueryAsset","Args":["iot1"]}'
     ```

28. **LocationBasedIoTStatus**:
   - **وظیفه کلی**: ثبت و به‌روزرسانی وضعیت دستگاه‌های IoT بر اساس فاصله.
   - **ساختار داده**:
     ```json
     {
       "deviceID": "string",
       "status": "string",
       "x": "string",
       "y": "string",
       "distance": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **UpdateIoTStatus(deviceID: string, status: string, x: string, y: string) -> error**:
       - **ورودی**: deviceID، status، x/y.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت وضعیت دستگاه IoT.
     - **QueryAsset(deviceID: string) -> IoTStatusRecord**:
       - **خروجی**: JSON ساختار IoTStatusRecord.
       - **سناریو**: بررسی وضعیت.
     - **QueryAllAssets() -> []IoTStatusRecord**:
       - **خروجی**: لیست تمام وضعیت‌ها.
       - **سناریو**: نمایش برای ممیزی.
     - **ValidateIoTStatusDistance(deviceID: string, maxDistance: string) -> bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی فاصله.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C IoTChannel -n LocationBasedIoTStatus -c '{"function":"UpdateIoTStatus","Args":["iot1","Active","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C IoTChannel -n LocationBasedIoTStatus -c '{"function":"QueryAsset","Args":["iot1"]}'
     ```

29. **LocationBasedIoTFault**:
   - **وظیفه کلی**: ثبت خطاها یا خرابی‌های دستگاه‌های IoT بر اساس فاصله.
   - **ساختار داده**:
     ```json
     {
       "deviceID": "string",
       "faultType": "string",
       "x": "string",
       "y": "string",
       "distance": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **ReportIoTFault(deviceID: string, faultType: string, x: string, y: string) -> error**:
       - **ورودی**: deviceID، faultType، x/y.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت خطای دستگاه IoT.
     - **QueryAsset(deviceID: string) -> IoTFaultRecord**:
       - **خروجی**: JSON ساختار IoTFaultRecord.
       - **سناریو**: بررسی خطا.
     - **QueryAllAssets() -> []IoTFaultRecord**:
       - **خروجی**: لیست تمام خطاها.
       - **سناریو**: نمایش برای ممیزی.
     - **ValidateIoTFaultDistance(deviceID: string, maxDistance: string) -> bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی فاصله.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C IoTChannel -n LocationBasedIoTFault -c '{"function":"ReportIoTFault","Args":["iot1","ConnectionLoss","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C IoTChannel -n LocationBasedIoTFault -c '{"function":"QueryAsset","Args":["iot1"]}'
     ```

30. **LocationBasedIoTSession**:
   - **وظیفه کلی**: مدیریت جلسات دستگاه‌های IoT بر اساس فاصله.
   - **ساختار داده**:
     ```json
     {
       "deviceID": "string",
       "sessionID": "string",
       "x": "string",
       "y": "string",
       "distance": "string",
       "status": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **StartIoTSession(deviceID: string, sessionID: string, x: string, y: string) -> error**:
       - **ورودی**: deviceID، sessionID، x/y.
       - **خروجی**: nil یا خطا.
       - **سناریو**: شروع جلسه برای دستگاه IoT.
     - **EndIoTSession(deviceID: string) -> error**:
       - **ورودی**: deviceID.
       - **خروجی**: nil یا خطا.
       - **سناریو**: پایان جلسه.
     - **QueryAsset(deviceID: string) -> IoTSessionRecord**:
       - **خروجی**: JSON ساختار IoTSessionRecord.
       - **سناریو**: بررسی جلسه.
     - **QueryAllAssets() -> []IoTSessionRecord**:
       - **خروجی**: لیست تمام جلسات.
       - **سناریو**: نمایش برای ممیزی.
     - **ValidateIoTSessionDistance(deviceID: string, maxDistance: string) -> bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی فاصله.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C IoTChannel -n LocationBasedIoTSession -c '{"function":"StartIoTSession","Args":["iot1","Session1","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode invoke -C IoTChannel -n LocationBasedIoTSession -c '{"function":"EndIoTSession","Args":["iot1"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C IoTChannel -n LocationBasedIoTSession -c '{"function":"QueryAsset","Args":["iot1"]}'
     ```

31. **LocationBasedIoTAuthentication**:
   - **وظیفه کلی**: احراز هویت دستگاه‌های IoT بر اساس فاصله و توکن.
   - **ساختار داده**:
     ```json
     {
       "deviceID": "string",
       "token": "string",
       "x": "string",
       "y": "string",
       "distance": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **AuthenticateIoTDevice(deviceID: string, token: string, x: string, y: string) -> error**:
       - **ورودی**: deviceID، token، x/y.
       - **خروجی**: nil یا خطا.
       - **سناریو**: احراز هویت دستگاه IoT.
     - **QueryAsset(deviceID: string) -> IoTAuthRecord**:
       - **خروجی**: JSON ساختار IoTAuthRecord.
       - **سناریو**: بررسی احراز هویت.
     - **QueryAllAssets() -> []IoTAuthRecord**:
       - **خروجی**: لیست تمام احراز هویت‌ها.
       - **سناریو**: نمایش برای ممیزی.
     - **ValidateIoTAuthDistance(deviceID: string, maxDistance: string) -> bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی فاصله.
     - **ValidateIoTToken(deviceID: string, token: string) -> bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی توکن.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C IoTChannel -n LocationBasedIoTAuthentication -c '{"function":"AuthenticateIoTDevice","Args":["iot1","token123","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C IoTChannel -n LocationBasedIoTAuthentication -c '{"function":"QueryAsset","Args":["iot1"]}'
     peer chaincode query -C IoTChannel -n LocationBasedIoTAuthentication -c '{"function":"ValidateIoTToken","Args":["iot1","token123"]}'
     ```

32. **LocationBasedIoTRegistration**:
   - **وظیفه کلی**: ثبت دستگاه‌های IoT در شبکه بر اساس فاصله.
   - **ساختار داده**:
     ```json
     {
       "deviceID": "string",
       "status": "string",
       "x": "string",
       "y": "string",
       "distance": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **RegisterIoTDevice(deviceID: string, status: string, x: string, y: string) -> error**:
       - **ورودی**: deviceID، status، x/y.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت دستگاه IoT.
     - **QueryAsset(deviceID: string) -> IoTRegistrationRecord**:
       - **خروجی**: JSON ساختار IoTRegistrationRecord.
       - **سناریو**: بررسی ثبت.
     - **QueryAllAssets() -> []IoTRegistrationRecord**:
       - **خروجی**: لیست تمام ثبت‌ها.
       - **سناریو**: نمایش برای ممیزی.
     - **ValidateIoTRegistrationDistance(deviceID: string, maxDistance: string) -> bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی فاصله.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C IoTChannel -n LocationBasedIoTRegistration -c '{"function":"RegisterIoTDevice","Args":["iot1","Registered","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C IoTChannel -n LocationBasedIoTRegistration -c '{"function":"QueryAsset","Args":["iot1"]}'
     ```

33. **LocationBasedIoTRevocation**:
   - **وظیفه کلی**: لغو ثبت دستگاه‌های IoT بر اساس فاصله.
   - **ساختار داده**:
     ```json
     {
       "deviceID": "string",
       "status": "string",
       "x": "string",
       "y": "string",
       "distance": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **RevokeIoTDevice(deviceID: string, status: string, x: string, y: string) -> error**:
       - **ورودی**: deviceID، status، x/y.
       - **خروجی**: nil یا خطا.
       - **سناریو**: لغو ثبت دستگاه IoT.
     - **QueryAsset(deviceID: string) -> IoTRevocationRecord**:
       - **خروجی**: JSON ساختار IoTRevocationRecord.
       - **سناریو**: بررسی لغو ثبت.
     - **QueryAllAssets() -> []IoTRevocationRecord**:
       - **خروجی**: لیست تمام لغو ثبت‌ها.
       - **سناریو**: نمایش برای ممیزی.
     - **ValidateIoTRevocationDistance(deviceID: string, maxDistance: string) -> bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی فاصله.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C IoTChannel -n LocationBasedIoTRevocation -c '{"function":"RevokeIoTDevice","Args":["iot1","Revoked","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C IoTChannel -n LocationBasedIoTRevocation -c '{"function":"QueryAsset","Args":["iot1"]}'
     ```

34. **LocationBasedIoTResource**:
   - **وظیفه کلی**: تخصیص منابع (مانند پهنای باند یا توان) به دستگاه‌های IoT بر اساس فاصله.
   - **ساختار داده**:
     ```json
     {
       "deviceID": "string",
       "resourceID": "string",
       "amount": "string",
       "x": "string",
       "y": "string",
       "distance": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **AllocateIoTResource(deviceID: string, resourceID: string, amount: string, x: string, y: string) -> error**:
       - **ورودی**: deviceID، resourceID، amount، x/y.
       - **خروجی**: nil یا خطا.
       - **سناریو**: تخصیص منبع به دستگاه IoT.
     - **QueryAsset(deviceID: string) -> IoTResourceAllocation**:
       - **خروجی**: JSON ساختار IoTResourceAllocation.
       - **سناریو**: بررسی تخصیص منبع.
     - **QueryAllAssets() -> []IoTResourceAllocation**:
       - **خروجی**: لیست تمام تخصیص‌های منبع.
       - **سناریو**: نمایش برای Network Map.
     - **ValidateIoTResourceDistance(deviceID: string, maxDistance: string) -> bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی فاصله.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C IoTChannel -n LocationBasedIoTResource -c '{"function":"AllocateIoTResource","Args":["iot1","Bandwidth","50Mbps","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C IoTChannel -n LocationBasedIoTResource -c '{"function":"QueryAsset","Args":["iot1"]}'
     ```

35. **LocationBasedUserActivity**:
   - **وظیفه کلی**: ثبت فعالیت‌های کاربر در شبکه بر اساس فاصله.
   - **ساختار داده**:
     ```json
     {
       "userID": "string",
       "activity": "string",
       "x": "string",
       "y": "string",
       "distance": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **RecordUserActivity(userID: string, activity: string, x: string, y: string) -> error**:
       - **ورودی**: userID، activity، x/y.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت فعالیت کاربر.
     - **QueryAsset(userID: string) -> UserActivityRecord**:
       - **خروجی**: JSON ساختار UserActivityRecord.
       - **سناریو**: بررسی فعالیت.
     - **QueryAllAssets() -> []UserActivityRecord**:
       - **خروجی**: لیست تمام فعالیت‌ها.
       - **سناریو**: نمایش برای ممیزی.
     - **ValidateUserActivityDistance(userID: string, maxDistance: string) -> bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی فاصله.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C AuditChannel -n LocationBasedUserActivity -c '{"function":"RecordUserActivity","Args":["user1","Login","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C AuditChannel -n LocationBasedUserActivity -c '{"function":"QueryAsset","Args":["user1"]}'
     ```
     # توضیحات قراردادهای هوشمند پروژه 6G Fabric Network - بخش 5

این فایل توضیحات جامع قراردادهای 35 تا 43 (از 85 قرارداد هوشمند) را ارائه می‌دهد. هر قرارداد شامل وظیفه کلی، ساختار داده، توابع (با ورودی/خروجی و سناریوی استفاده)، و مثال دستورات invoke/query است.

## قراردادهای عمومی

35. **AuthenticateUser**:
   - **وظیفه کلی**: احراز هویت کاربران با استفاده از توکن.
   - **ساختار داده**:
     ```json
     {
       "userID": "string",
       "token": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Authenticate(userID: string, token: string) -> error**:
       - **ورودی**: userID، token.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت توکن احراز هویت کاربر.
     - **QueryAsset(userID: string) -> UserAuthRecord**:
       - **خروجی**: JSON ساختار UserAuthRecord.
       - **سناریو**: بررسی احراز هویت.
     - **QueryAllAssets() -> []UserAuthRecord**:
       - **خروجی**: لیست تمام احراز هویت‌ها.
       - **سناریو**: نمایش برای ممیزی.
     - **ValidateToken(userID: string, token: string) -> bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی توکن.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C AuthChannel -n AuthenticateUser -c '{"function":"Authenticate","Args":["user1","token123"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C AuthChannel -n AuthenticateUser -c '{"function":"QueryAsset","Args":["user1"]}'
     peer chaincode query -C AuthChannel -n AuthenticateUser -c '{"function":"ValidateToken","Args":["user1","token123"]}'
     ```

36. **AuthenticateIoT**:
   - **وظیفه کلی**: احراز هویت دستگاه‌های IoT با استفاده از توکن.
   - **ساختار داده**:
     ```json
     {
       "deviceID": "string",
       "token": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Authenticate(deviceID: string, token: string) -> error**:
       - **ورودی**: deviceID، token.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت توکن احراز هویت دستگاه IoT.
     - **QueryAsset(deviceID: string) -> IoTAuthRecord**:
       - **خروجی**: JSON ساختار IoTAuthRecord.
       - **سناریو**: بررسی احراز هویت.
     - **QueryAllAssets() -> []IoTAuthRecord**:
       - **خروجی**: لیست تمام احراز هویت‌ها.
       - **سناریو**: نمایش برای ممیزی.
     - **ValidateToken(deviceID: string, token: string) -> bool, error**:
       - **خروجی**: true/false، خطا.
       - **سناریو**: اعتبارسنجی توکن.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C IoTChannel -n AuthenticateIoT -c '{"function":"Authenticate","Args":["iot1","token123"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C IoTChannel -n AuthenticateIoT -c '{"function":"QueryAsset","Args":["iot1"]}'
     peer chaincode query -C IoTChannel -n AuthenticateIoT -c '{"function":"ValidateToken","Args":["iot1","token123"]}'
     ```

37. **ConnectUser**:
   - **وظیفه کلی**: مدیریت اتصال کاربران به آنتن‌ها.
   - **ساختار داده**:
     ```json
     {
       "userID": "string",
       "antennaID": "string",
       "status": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Connect(userID: string, antennaID: string) -> error**:
       - **ورودی**: userID، antennaID.
       - **خروجی**: nil یا خطا.
       - **سناریو**: اتصال کاربر به آنتن.
     - **Disconnect(userID: string) -> error**:
       - **ورودی**: userID.
       - **خروجی**: nil یا خطا.
       - **سناریو**: قطع اتصال کاربر.
     - **QueryAsset(userID: string) -> UserConnection**:
       - **خروجی**: JSON ساختار UserConnection.
       - **سناریو**: بررسی اتصال.
     - **QueryAllAssets() -> []UserConnection**:
       - **خروجی**: لیست تمام اتصال‌ها.
       - **سناریو**: نمایش برای Network Map.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C ConnectivityChannel -n ConnectUser -c '{"function":"Connect","Args":["user1","Antenna1"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode invoke -C ConnectivityChannel -n ConnectUser -c '{"function":"Disconnect","Args":["user1"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C ConnectivityChannel -n ConnectUser -c '{"function":"QueryAsset","Args":["user1"]}'
     ```

38. **ConnectIoT**:
   - **وظیفه کلی**: مدیریت اتصال دستگاه‌های IoT به آنتن‌ها.
   - **ساختار داده**:
     ```json
     {
       "deviceID": "string",
       "antennaID": "string",
       "status": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Connect(deviceID: string, antennaID: string) -> error**:
       - **ورودی**: deviceID، antennaID.
       - **خروجی**: nil یا خطا.
       - **سناریو**: اتصال دستگاه IoT به آنتن.
     - **Disconnect(deviceID: string) -> error**:
       - **ورودی**: deviceID.
       - **خروجی**: nil یا خطا.
       - **سناریو**: قطع اتصال دستگاه.
     - **QueryAsset(deviceID: string) -> IoTConnection**:
       - **خروجی**: JSON ساختار IoTConnection.
       - **سناریو**: بررسی اتصال.
     - **QueryAllAssets() -> []IoTConnection**:
       - **خروجی**: لیست تمام اتصال‌ها.
       - **سناریو**: نمایش برای Network Map.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C IoTChannel -n ConnectIoT -c '{"function":"Connect","Args":["iot1","Antenna1"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode invoke -C IoTChannel -n ConnectIoT -c '{"function":"Disconnect","Args":["iot1"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C IoTChannel -n ConnectIoT -c '{"function":"QueryAsset","Args":["iot1"]}'
     ```

39. **RegisterUser**:
   - **وظیفه کلی**: ثبت کاربران در شبکه.
   - **ساختار داده**:
     ```json
     {
       "userID": "string",
       "status": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Register(userID: string, status: string) -> error**:
       - **ورودی**: userID، status.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت کاربر.
     - **QueryAsset(userID: string) -> UserRegistration**:
       - **خروجی**: JSON ساختار UserRegistration.
       - **سناریو**: بررسی ثبت.
     - **QueryAllAssets() -> []UserRegistration**:
       - **خروجی**: لیست تمام ثبت‌ها.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C AuthChannel -n RegisterUser -c '{"function":"Register","Args":["user1","Registered"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C AuthChannel -n RegisterUser -c '{"function":"QueryAsset","Args":["user1"]}'
     ```

40. **RegisterIoT**:
   - **وظیفه کلی**: ثبت دستگاه‌های IoT در شبکه.
   - **ساختار داده**:
     ```json
     {
       "deviceID": "string",
       "status": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Register(deviceID: string, status: string) -> error**:
       - **ورودی**: deviceID، status.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت دستگاه IoT.
     - **QueryAsset(deviceID: string) -> IoTRegistration**:
       - **خروجی**: JSON ساختار IoTRegistration.
       - **سناریو**: بررسی ثبت.
     - **QueryAllAssets() -> []IoTRegistration**:
       - **خروجی**: لیست تمام ثبت‌ها.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C IoTChannel -n RegisterIoT -c '{"function":"Register","Args":["iot1","Registered"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C IoTChannel -n RegisterIoT -c '{"function":"QueryAsset","Args":["iot1"]}'
     ```

41. **RevokeUser**:
   - **وظیفه کلی**: لغو ثبت کاربران از شبکه.
   - **ساختار داده**:
     ```json
     {
       "userID": "string",
       "status": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Revoke(userID: string, status: string) -> error**:
       - **ورودی**: userID، status.
       - **خروجی**: nil یا خطا.
       - **سناریو**: لغو ثبت کاربر.
     - **QueryAsset(userID: string) -> UserRevocation**:
       - **خروجی**: JSON ساختار UserRevocation.
       - **سناریو**: بررسی لغو ثبت.
     - **QueryAllAssets() -> []UserRevocation**:
       - **خروجی**: لیست تمام لغو ثبت‌ها.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C AuthChannel -n RevokeUser -c '{"function":"Revoke","Args":["user1","Revoked"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C AuthChannel -n RevokeUser -c '{"function":"QueryAsset","Args":["user1"]}'
     ```

42. **RevokeIoT**:
   - **وظیفه کلی**: لغو ثبت دستگاه‌های IoT از شبکه.
   - **ساختار داده**:
     ```json
     {
       "deviceID": "string",
       "status": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Revoke(deviceID: string, status: string) -> error**:
       - **ورودی**: deviceID، status.
       - **خروجی**: nil یا خطا.
       - **سناریو**: لغو ثبت دستگاه IoT.
     - **QueryAsset(deviceID: string) -> IoTRevocation**:
       - **خروجی**: JSON ساختار IoTRevocation.
       - **سناریو**: بررسی لغو ثبت.
     - **QueryAllAssets() -> []IoTRevocation**:
       - **خروجی**: لیست تمام لغو ثبت‌ها.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C IoTChannel -n RevokeIoT -c '{"function":"Revoke","Args":["iot1","Revoked"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C IoTChannel -n RevokeIoT -c '{"function":"QueryAsset","Args":["iot1"]}'
     ```

43. **AssignRole**:
   - **وظیفه کلی**: تخصیص نقش به کاربران.
   - **ساختار داده**:
     ```json
     {
       "userID": "string",
       "role": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Assign(userID: string, role: string) -> error**:
       - **ورودی**: userID، role.
       - **خروجی**: nil یا خطا.
       - **سناریو**: تخصیص نقش به کاربر.
     - **QueryAsset(userID: string) -> RoleAssignment**:
       - **خروجی**: JSON ساختار RoleAssignment.
       - **سناریو**: بررسی نقش.
     - **QueryAllAssets() -> []RoleAssignment**:
       - **خروجی**: لیست تمام نقش‌ها.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C PolicyChannel -n AssignRole -c '{"function":"Assign","Args":["user1","Admin"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C PolicyChannel -n AssignRole -c '{"function":"QueryAsset","Args":["user1"]}'
     ```
     # توضیحات قراردادهای هوشمند پروژه 6G Fabric Network - بخش 6

این فایل توضیحات جامع قراردادهای 44 تا 51 (از 85 قرارداد هوشمند) را ارائه می‌دهد. هر قرارداد شامل وظیفه کلی، ساختار داده، توابع (با ورودی/خروجی و سناریوی استفاده)، و مثال دستورات invoke/query است.

## قراردادهای ممیزی و مانیتورینگ

44. **MonitorNetwork**:
   - **وظیفه کلی**: مانیتورینگ وضعیت کلی شبکه.
   - **ساختار داده**:
     ```json
     {
       "networkID": "string",
       "status": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **RecordStatus(networkID: string, status: string) -> error**:
       - **ورودی**: networkID، status.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت وضعیت شبکه.
     - **QueryAsset(networkID: string) -> NetworkMonitorRecord**:
       - **خروجی**: JSON ساختار NetworkMonitorRecord.
       - **سناریو**: بررسی وضعیت شبکه.
     - **QueryAllAssets() -> []NetworkMonitorRecord**:
       - **خروجی**: لیست تمام وضعیت‌ها.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C AuditChannel -n MonitorNetwork -c '{"function":"RecordStatus","Args":["network1","Stable"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C AuditChannel -n MonitorNetwork -c '{"function":"QueryAsset","Args":["network1"]}'
     ```

45. **MonitorIoT**:
   - **وظیفه کلی**: مانیتورینگ وضعیت دستگاه‌های IoT.
   - **ساختار داده**:
     ```json
     {
       "deviceID": "string",
       "status": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **RecordStatus(deviceID: string, status: string) -> error**:
       - **ورودی**: deviceID، status.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت وضعیت دستگاه IoT.
     - **QueryAsset(deviceID: string) -> IoTMonitorRecord**:
       - **خروجی**: JSON ساختار IoTMonitorRecord.
       - **سناریو**: بررسی وضعیت دستگاه.
     - **QueryAllAssets() -> []IoTMonitorRecord**:
       - **خروجی**: لیست تمام وضعیت‌ها.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C IoTChannel -n MonitorIoT -c '{"function":"RecordStatus","Args":["iot1","Active"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C IoTChannel -n MonitorIoT -c '{"function":"QueryAsset","Args":["iot1"]}'
     ```

46. **LogFault**:
   - **وظیفه کلی**: ثبت خطاها یا خرابی‌های شبکه.
   - **ساختار داده**:
     ```json
     {
       "entityID": "string",
       "faultType": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Log(entityID: string, faultType: string) -> error**:
       - **ورودی**: entityID، faultType.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت خطا.
     - **QueryAsset(entityID: string) -> FaultLog**:
       - **خروجی**: JSON ساختار FaultLog.
       - **سناریو**: بررسی خطا.
     - **QueryAllAssets() -> []FaultLog**:
       - **خروجی**: لیست تمام خطاها.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C AuditChannel -n LogFault -c '{"function":"Log","Args":["entity1","ConnectionLoss"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C AuditChannel -n LogFault -c '{"function":"QueryAsset","Args":["entity1"]}'
     ```

47. **LogPerformance**:
   - **وظیفه کلی**: ثبت معیارهای عملکرد شبکه.
   - **ساختار داده**:
     ```json
     {
       "entityID": "string",
       "metric": "string",
       "value": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Log(entityID: string, metric: string, value: string) -> error**:
       - **ورودی**: entityID، metric، value.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت معیار عملکرد.
     - **QueryAsset(entityID: string) -> PerformanceLog**:
       - **خروجی**: JSON ساختار PerformanceLog.
       - **سناریو**: بررسی عملکرد.
     - **QueryAllAssets() -> []PerformanceLog**:
       - **خروجی**: لیست تمام معیارها.
       - **سناریو**: نمایش برای Network Map.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C PerformanceChannel -n LogPerformance -c '{"function":"Log","Args":["entity1","Latency","50ms"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C PerformanceChannel -n LogPerformance -c '{"function":"QueryAsset","Args":["entity1"]}'
     ```

48. **LogSession**:
   - **وظیفه کلی**: ثبت جلسات کاربران یا دستگاه‌ها.
   - **ساختار داده**:
     ```json
     {
       "entityID": "string",
       "sessionID": "string",
       "status": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Log(entityID: string, sessionID: string, status: string) -> error**:
       - **ورودی**: entityID، sessionID، status.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت جلسه.
     - **QueryAsset(entityID: string) -> SessionLog**:
       - **خروجی**: JSON ساختار SessionLog.
       - **سناریو**: بررسی جلسه.
     - **QueryAllAssets() -> []SessionLog**:
       - **خروجی**: لیست تمام جلسات.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C SessionChannel -n LogSession -c '{"function":"Log","Args":["user1","Session1","Active"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C SessionChannel -n LogSession -c '{"function":"QueryAsset","Args":["user1"]}'
     ```

49. **LogTraffic**:
   - **وظیفه کلی**: ثبت ترافیک شبکه.
   - **ساختار داده**:
     ```json
     {
       "entityID": "string",
       "traffic": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Log(entityID: string, traffic: string) -> error**:
       - **ورودی**: entityID، traffic.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت ترافیک شبکه.
     - **QueryAsset(entityID: string) -> TrafficLog**:
       - **خروجی**: JSON ساختار TrafficLog.
       - **سناریو**: بررسی ترافیک.
     - **QueryAllAssets() -> []TrafficLog**:
       - **خروجی**: لیست تمام ترافیک‌ها.
       - **سناریو**: نمایش برای Network Map.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C PerformanceChannel -n LogTraffic -c '{"function":"Log","Args":["entity1","500MB"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C PerformanceChannel -n LogTraffic -c '{"function":"QueryAsset","Args":["entity1"]}'
     ```

50. **LogInterference**:
   - **وظیفه کلی**: ثبت سطح تداخل شبکه.
   - **ساختار داده**:
     ```json
     {
       "entityID": "string",
       "interferenceLevel": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Log(entityID: string, interferenceLevel: string) -> error**:
       - **ورودی**: entityID، interferenceLevel.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت سطح تداخل.
     - **QueryAsset(entityID: string) -> InterferenceLog**:
       - **خروجی**: JSON ساختار InterferenceLog.
       - **سناریو**: بررسی تداخل.
     - **QueryAllAssets() -> []InterferenceLog**:
       - **خروجی**: لیست تمام تداخل‌ها.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C PerformanceChannel -n LogInterference -c '{"function":"Log","Args":["entity1","Low"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C PerformanceChannel -n LogInterference -c '{"function":"QueryAsset","Args":["entity1"]}'
     ```

51. **LogResourceAudit**:
   - **وظیفه کلی**: ثبت ممیزی منابع تخصیص‌یافته.
   - **ساختار داده**:
     ```json
     {
       "entityID": "string",
       "resource": "string",
       "amount": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Log(entityID: string, resource: string, amount: string) -> error**:
       - **ورودی**: entityID، resource، amount.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت ممیزی منابع.
     - **QueryAsset(entityID: string) -> ResourceAuditLog**:
       - **خروجی**: JSON ساختار ResourceAuditLog.
       - **سناریو**: بررسی ممیزی.
     - **QueryAllAssets() -> []ResourceAuditLog**:
       - **خروجی**: لیست تمام ممیزی‌ها.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C AuditChannel -n LogResourceAudit -c '{"function":"Log","Args":["entity1","Bandwidth","100Mbps"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C AuditChannel -n LogResourceAudit -c '{"function":"QueryAsset","Args":["entity1"]}'
     ```
     # توضیحات قراردادهای هوشمند پروژه 6G Fabric Network - بخش 7

این فایل توضیحات جامع قراردادهای 52 تا 60 (از 85 قرارداد هوشمند) را ارائه می‌دهد. هر قرارداد شامل وظیفه کلی، ساختار داده، توابع (با ورودی/خروجی و سناریوی استفاده)، و مثال دستورات invoke/query است.

## قراردادهای مدیریت و بهینه‌سازی

52. **BalanceLoad**:
   - **وظیفه کلی**: متعادل‌سازی بار شبکه.
   - **ساختار داده**:
     ```json
     {
       "networkID": "string",
       "load": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Balance(networkID: string, load: string) -> error**:
       - **ورودی**: networkID، load.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت بار شبکه برای متعادل‌سازی.
     - **QueryAsset(networkID: string) -> LoadBalanceRecord**:
       - **خروجی**: JSON ساختار LoadBalanceRecord.
       - **سناریو**: بررسی بار شبکه.
     - **QueryAllAssets() -> []LoadBalanceRecord**:
       - **خروجی**: لیست تمام رکوردهای بار.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C PerformanceChannel -n BalanceLoad -c '{"function":"Balance","Args":["network1","Balanced"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C PerformanceChannel -n BalanceLoad -c '{"function":"QueryAsset","Args":["network1"]}'
     ```

53. **AllocateResource**:
   - **وظیفه کلی**: تخصیص منابع به موجودیت‌ها.
   - **ساختار داده**:
     ```json
     {
       "entityID": "string",
       "resource": "string",
       "amount": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Allocate(entityID: string, resource: string, amount: string) -> error**:
       - **ورودی**: entityID، resource، amount.
       - **خروجی**: nil یا خطا.
       - **سناریو**: تخصیص منابع.
     - **QueryAsset(entityID: string) -> ResourceAllocation**:
       - **خروجی**: JSON ساختار ResourceAllocation.
       - **سناریو**: بررسی تخصیص.
     - **QueryAllAssets() -> []ResourceAllocation**:
       - **خروجی**: لیست تمام تخصیص‌ها.
       - **سناریو**: نمایش برای Network Map.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C ResourceChannel -n AllocateResource -c '{"function":"Allocate","Args":["entity1","Bandwidth","100Mbps"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C ResourceChannel -n AllocateResource -c '{"function":"QueryAsset","Args":["entity1"]}'
     ```

54. **OptimizeNetwork**:
   - **وظیفه کلی**: بهینه‌سازی شبکه با استراتژی‌های مشخص.
   - **ساختار داده**:
     ```json
     {
       "networkID": "string",
       "strategy": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Optimize(networkID: string, strategy: string) -> error**:
       - **ورودی**: networkID، strategy.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت استراتژی بهینه‌سازی.
     - **QueryAsset(networkID: string) -> NetworkOptimization**:
       - **خروجی**: JSON ساختار NetworkOptimization.
       - **سناریو**: بررسی استراتژی.
     - **QueryAllAssets() -> []NetworkOptimization**:
       - **خروجی**: لیست تمام استراتژی‌ها.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C PerformanceChannel -n OptimizeNetwork -c '{"function":"Optimize","Args":["network1","DynamicRouting"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C PerformanceChannel -n OptimizeNetwork -c '{"function":"QueryAsset","Args":["network1"]}'
     ```

55. **ManageSession**:
   - **وظیفه کلی**: مدیریت جلسات موجودیت‌ها.
   - **ساختار داده**:
     ```json
     {
       "entityID": "string",
       "sessionID": "string",
       "status": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **StartSession(entityID: string, sessionID: string) -> error**:
       - **ورودی**: entityID، sessionID.
       - **خروجی**: nil یا خطا.
       - **سناریو**: شروع جلسه.
     - **EndSession(entityID: string) -> error**:
       - **ورودی**: entityID.
       - **خروجی**: nil یا خطا.
       - **سناریو**: پایان جلسه.
     - **QueryAsset(entityID: string) -> SessionRecord**:
       - **خروجی**: JSON ساختار SessionRecord.
       - **سناریو**: بررسی جلسه.
     - **QueryAllAssets() -> []SessionRecord**:
       - **خروجی**: لیست تمام جلسات.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C SessionChannel -n ManageSession -c '{"function":"StartSession","Args":["entity1","Session1"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode invoke -C SessionChannel -n ManageSession -c '{"function":"EndSession","Args":["entity1"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C SessionChannel -n ManageSession -c '{"function":"QueryAsset","Args":["entity1"]}'
     ```

56. **LogNetworkPerformance**:
   - **وظیفه کلی**: ثبت معیارهای عملکرد شبکه.
   - **ساختار داده**:
     ```json
     {
       "networkID": "string",
       "metric": "string",
       "value": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Log(networkID: string, metric: string, value: string) -> error**:
       - **ورودی**: networkID، metric، value.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت معیار عملکرد شبکه.
     - **QueryAsset(networkID: string) -> NetworkPerformanceLog**:
       - **خروجی**: JSON ساختار NetworkPerformanceLog.
       - **سناریو**: بررسی عملکرد.
     - **QueryAllAssets() -> []NetworkPerformanceLog**:
       - **خروجی**: لیست تمام معیارها.
       - **سناریو**: نمایش برای Network Map.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C PerformanceChannel -n LogNetworkPerformance -c '{"function":"Log","Args":["network1","Throughput","1Gbps"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C PerformanceChannel -n LogNetworkPerformance -c '{"function":"QueryAsset","Args":["network1"]}'
     ```

57. **LogUserActivity**:
   - **وظیفه کلی**: ثبت فعالیت‌های کاربران.
   - **ساختار داده**:
     ```json
     {
       "userID": "string",
       "activity": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Log(userID: string, activity: string) -> error**:
       - **ورودی**: userID، activity.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت فعالیت کاربر.
     - **QueryAsset(userID: string) -> UserActivityLog**:
       - **خروجی**: JSON ساختار UserActivityLog.
       - **سناریو**: بررسی فعالیت.
     - **QueryAllAssets() -> []UserActivityLog**:
       - **خروجی**: لیست تمام فعالیت‌ها.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C AuditChannel -n LogUserActivity -c '{"function":"Log","Args":["user1","Login"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C AuditChannel -n LogUserActivity -c '{"function":"QueryAsset","Args":["user1"]}'
     ```

58. **LogIoTActivity**:
   - **وظیفه کلی**: ثبت فعالیت‌های دستگاه‌های IoT.
   - **ساختار داده**:
     ```json
     {
       "deviceID": "string",
       "activity": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Log(deviceID: string, activity: string) -> error**:
       - **ورودی**: deviceID، activity.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت فعالیت دستگاه IoT.
     - **QueryAsset(deviceID: string) -> IoTActivityLog**:
       - **خروجی**: JSON ساختار IoTActivityLog.
       - **سناریو**: بررسی فعالیت.
     - **QueryAllAssets() -> []IoTActivityLog**:
       - **خروجی**: لیست تمام فعالیت‌ها.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C IoTChannel -n LogIoTActivity -c '{"function":"Log","Args":["iot1","DataTransmission"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C IoTChannel -n LogIoTActivity -c '{"function":"QueryAsset","Args":["iot1"]}'
     ```

59. **LogSessionAudit**:
   - **وظیفه کلی**: ثبت ممیزی جلسات.
   - **ساختار داده**:
     ```json
     {
       "entityID": "string",
       "sessionID": "string",
       "action": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Log(entityID: string, sessionID: string, action: string) -> error**:
       - **ورودی**: entityID، sessionID، action.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت ممیزی جلسه.
     - **QueryAsset(entityID: string) -> SessionAuditLog**:
       - **خروجی**: JSON ساختار SessionAuditLog.
       - **سناریو**: بررسی ممیزی.
     - **QueryAllAssets() -> []SessionAuditLog**:
       - **خروجی**: لیست تمام ممیزی‌ها.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C AuditChannel -n LogSessionAudit -c '{"function":"Log","Args":["entity1","Session1","Start"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C AuditChannel -n LogSessionAudit -c '{"function":"QueryAsset","Args":["entity1"]}'
     ```

60. **LogConnectionAudit**:
   - **وظیفه کلی**: ثبت ممیزی اتصالات.
   - **ساختار داده**:
     ```json
     {
       "entityID": "string",
       "antennaID": "string",
       "action": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Log(entityID: string, antennaID: string, action: string) -> error**:
       - **ورودی**: entityID، antennaID، action.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت ممیزی اتصال.
     - **QueryAsset(entityID: string) -> ConnectionAuditLog**:
       - **خروجی**: JSON ساختار ConnectionAuditLog.
       - **سناریو**: بررسی ممیزی.
     - **QueryAllAssets() -> []ConnectionAuditLog**:
       - **خروجی**: لیست تمام ممیزی‌ها.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C AuditChannel -n LogConnectionAudit -c '{"function":"Log","Args":["entity1","Antenna1","Connect"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C AuditChannel -n LogConnectionAudit -c '{"function":"QueryAsset","Args":["entity1"]}'
     ```
     # توضیحات قراردادهای هوشمند پروژه 6G Fabric Network - بخش 8

این فایل توضیحات جامع قراردادهای 61 تا 68 (از 85 قرارداد هوشمند) را ارائه می‌دهد. هر قرارداد شامل وظیفه کلی، ساختار داده، توابع (با ورودی/خروجی و سناریوی استفاده)، و مثال دستورات invoke/query است.

## قراردادهای امنیتی

61. **EncryptData**:
   - **وظیفه کلی**: رمزگذاری داده‌ها برای موجودیت‌ها.
   - **ساختار داده**:
     ```json
     {
       "entityID": "string",
       "data": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Encrypt(entityID: string, data: string) -> error**:
       - **ورودی**: entityID، data.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت داده رمزگذاری‌شده.
     - **QueryAsset(entityID: string) -> EncryptedData**:
       - **خروجی**: JSON ساختار EncryptedData.
       - **سناریو**: بررسی داده رمزگذاری‌شده.
     - **QueryAllAssets() -> []EncryptedData**:
       - **خروجی**: لیست تمام داده‌های رمزگذاری‌شده.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C SecurityChannel -n EncryptData -c '{"function":"Encrypt","Args":["entity1","encrypted_data"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C SecurityChannel -n EncryptData -c '{"function":"QueryAsset","Args":["entity1"]}'
     ```

62. **DecryptData**:
   - **وظیفه کلی**: رمزگشایی داده‌ها برای موجودیت‌ها.
   - **ساختار داده**:
     ```json
     {
       "entityID": "string",
       "data": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Decrypt(entityID: string, data: string) -> error**:
       - **ورودی**: entityID، data.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت داده رمزگشایی‌شده.
     - **QueryAsset(entityID: string) -> DecryptedData**:
       - **خروجی**: JSON ساختار DecryptedData.
       - **سناریو**: بررسی داده رمزگشایی‌شده.
     - **QueryAllAssets() -> []DecryptedData**:
       - **خروجی**: لیست تمام داده‌های رمزگشایی‌شده.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C SecurityChannel -n DecryptData -c '{"function":"Decrypt","Args":["entity1","decrypted_data"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C SecurityChannel -n DecryptData -c '{"function":"QueryAsset","Args":["entity1"]}'
     ```

63. **SecureCommunication**:
   - **وظیفه کلی**: مدیریت ارتباطات امن.
   - **ساختار داده**:
     ```json
     {
       "entityID": "string",
       "channelID": "string",
       "status": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Establish(entityID: string, channelID: string) -> error**:
       - **ورودی**: entityID، channelID.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ایجاد ارتباط امن.
     - **QueryAsset(entityID: string) -> CommunicationRecord**:
       - **خروجی**: JSON ساختار CommunicationRecord.
       - **سناریو**: بررسی ارتباط.
     - **QueryAllAssets() -> []CommunicationRecord**:
       - **خروجی**: لیست تمام ارتباطات.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C SecurityChannel -n SecureCommunication -c '{"function":"Establish","Args":["entity1","Channel1"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C SecurityChannel -n SecureCommunication -c '{"function":"QueryAsset","Args":["entity1"]}'
     ```

64. **VerifyIdentity**:
   - **وظیفه کلی**: تأیید هویت موجودیت‌ها.
   - **ساختار داده**:
     ```json
     {
       "entityID": "string",
       "verified": "boolean",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Verify(entityID: string, verified: bool) -> error**:
       - **ورودی**: entityID، verified.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت وضعیت تأیید هویت.
     - **QueryAsset(entityID: string) -> IdentityRecord**:
       - **خروجی**: JSON ساختار IdentityRecord.
       - **سناریو**: بررسی تأیید هویت.
     - **QueryAllAssets() -> []IdentityRecord**:
       - **خروجی**: لیست تمام تأییدها.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C SecurityChannel -n VerifyIdentity -c '{"function":"Verify","Args":["entity1","true"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C SecurityChannel -n VerifyIdentity -c '{"function":"QueryAsset","Args":["entity1"]}'
     ```

65. **SetPolicy**:
   - **وظیفه کلی**: تنظیم سیاست‌های شبکه.
   - **ساختار داده**:
     ```json
     {
       "policyID": "string",
       "policy": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Set(policyID: string, policy: string) -> error**:
       - **ورودی**: policyID، policy.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت سیاست شبکه.
     - **QueryAsset(policyID: string) -> PolicyRecord**:
       - **خروجی**: JSON ساختار PolicyRecord.
       - **سناریو**: بررسی سیاست.
     - **QueryAllAssets() -> []PolicyRecord**:
       - **خروجی**: لیست تمام سیاست‌ها.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C PolicyChannel -n SetPolicy -c '{"function":"Set","Args":["policy1","AllowAll"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C PolicyChannel -n SetPolicy -c '{"function":"QueryAsset","Args":["policy1"]}'
     ```

66. **GetPolicy**:
   - **وظیفه کلی**: دریافت سیاست‌های شبکه.
   - **ساختار داده**:
     ```json
     {
       "policyID": "string",
       "policy": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **QueryAsset(policyID: string) -> PolicyRecord**:
       - **خروجی**: JSON ساختار PolicyRecord.
       - **سناریو**: بررسی سیاست.
     - **QueryAllAssets() -> []PolicyRecord**:
       - **خروجی**: لیست تمام سیاست‌ها.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode query -C PolicyChannel -n GetPolicy -c '{"function":"QueryAsset","Args":["policy1"]}'
     ```

67. **UpdatePolicy**:
   - **وظیفه کلی**: به‌روزرسانی سیاست‌های شبکه.
   - **ساختار داده**:
     ```json
     {
       "policyID": "string",
       "policy": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Update(policyID: string, policy: string) -> error**:
       - **ورودی**: policyID، policy.
       - **خروجی**: nil یا خطا.
       - **سناریو**: به‌روزرسانی سیاست شبکه.
     - **QueryAsset(policyID: string) -> PolicyRecord**:
       - **خروجی**: JSON ساختار PolicyRecord.
       - **سناریو**: بررسی سیاست.
     - **QueryAllAssets() -> []PolicyRecord**:
       - **خروجی**: لیست تمام سیاست‌ها.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C PolicyChannel -n UpdatePolicy -c '{"function":"Update","Args":["policy1","RestrictAccess"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C PolicyChannel -n UpdatePolicy -c '{"function":"QueryAsset","Args":["policy1"]}'
     ```

68. **LogPolicyAudit**:
   - **وظیفه کلی**: ثبت ممیزی سیاست‌های شبکه.
   - **ساختار داده**:
     ```json
     {
       "policyID": "string",
       "action": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Log(policyID: string, action: string) -> error**:
       - **ورودی**: policyID، action.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت ممیزی سیاست.
     - **QueryAsset(policyID: string) -> PolicyAuditLog**:
       - **خروجی**: JSON ساختار PolicyAuditLog.
       - **سناریو**: بررسی ممیزی.
     - **QueryAllAssets() -> []PolicyAuditLog**:
       - **خروجی**: لیست تمام ممیزی‌ها.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C AuditChannel -n LogPolicyAudit -c '{"function":"Log","Args":["policy1","Updated"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C AuditChannel -n LogPolicyAudit -c '{"function":"QueryAsset","Args":["policy1"]}'
     ```
     # توضیحات قراردادهای هوشمند پروژه 6G Fabric Network - بخش 9

این فایل توضیحات جامع قراردادهای 69 تا 77 (از 85 قرارداد هوشمند) را ارائه می‌دهد. هر قرارداد شامل وظیفه کلی، ساختار داده، توابع (با ورودی/خروجی و سناریوی استفاده)، و مثال دستورات invoke/query است.

## قراردادهای مدیریت و مانیتورینگ

69. **ManageNetwork**:
   - **وظیفه کلی**: مدیریت وضعیت شبکه.
   - **ساختار داده**:
     ```json
     {
       "networkID": "string",
       "status": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **UpdateNetworkStatus(networkID: string, status: string) -> error**:
       - **ورودی**: networkID، status.
       - **خروجی**: nil یا خطا.
       - **سناریو**: به‌روزرسانی وضعیت شبکه.
     - **QueryAsset(networkID: string) -> NetworkRecord**:
       - **خروجی**: JSON ساختار NetworkRecord.
       - **سناریو**: بررسی وضعیت شبکه.
     - **QueryAllAssets() -> []NetworkRecord**:
       - **خروجی**: لیست تمام وضعیت‌ها.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C NetworkChannel -n ManageNetwork -c '{"function":"UpdateNetworkStatus","Args":["network1","Active"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C NetworkChannel -n ManageNetwork -c '{"function":"QueryAsset","Args":["network1"]}'
     ```

70. **ManageAntenna**:
   - **وظیفه کلی**: مدیریت وضعیت آنتن‌ها.
   - **ساختار داده**:
     ```json
     {
       "antennaID": "string",
       "status": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **UpdateAntennaStatus(antennaID: string, status: string) -> error**:
       - **ورودی**: antennaID، status.
       - **خروجی**: nil یا خطا.
       - **سناریو**: به‌روزرسانی وضعیت آنتن.
     - **QueryAsset(antennaID: string) -> AntennaRecord**:
       - **خروجی**: JSON ساختار AntennaRecord.
       - **سناریو**: بررسی وضعیت آنتن.
     - **QueryAllAssets() -> []AntennaRecord**:
       - **خروجی**: لیست تمام وضعیت‌ها.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C ResourceChannel -n ManageAntenna -c '{"function":"UpdateAntennaStatus","Args":["Antenna1","Operational"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C ResourceChannel -n ManageAntenna -c '{"function":"QueryAsset","Args":["Antenna1"]}'
     ```

71. **ManageIoTDevice**:
   - **وظیفه کلی**: مدیریت وضعیت دستگاه‌های IoT.
   - **ساختار داده**:
     ```json
     {
       "deviceID": "string",
       "status": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **UpdateDeviceStatus(deviceID: string, status: string) -> error**:
       - **ورودی**: deviceID، status.
       - **خروجی**: nil یا خطا.
       - **سناریو**: به‌روزرسانی وضعیت دستگاه IoT.
     - **QueryAsset(deviceID: string) -> IoTDeviceRecord**:
       - **خروجی**: JSON ساختار IoTDeviceRecord.
       - **سناریو**: بررسی وضعیت دستگاه.
     - **QueryAllAssets() -> []IoTDeviceRecord**:
       - **خروجی**: لیست تمام وضعیت‌ها.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C IoTChannel -n ManageIoTDevice -c '{"function":"UpdateDeviceStatus","Args":["iot1","Active"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C IoTChannel -n ManageIoTDevice -c '{"function":"QueryAsset","Args":["iot1"]}'
     ```

72. **ManageUser**:
   - **وظیفه کلی**: مدیریت وضعیت کاربران.
   - **ساختار داده**:
     ```json
     {
       "userID": "string",
       "status": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **UpdateUserStatus(userID: string, status: string) -> error**:
       - **ورودی**: userID، status.
       - **خروجی**: nil یا خطا.
       - **سناریو**: به‌روزرسانی وضعیت کاربر.
     - **QueryAsset(userID: string) -> UserRecord**:
       - **خروجی**: JSON ساختار UserRecord.
       - **سناریو**: بررسی وضعیت کاربر.
     - **QueryAllAssets() -> []UserRecord**:
       - **خروجی**: لیست تمام وضعیت‌ها.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C AuthChannel -n ManageUser -c '{"function":"UpdateUserStatus","Args":["user1","Active"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C AuthChannel -n ManageUser -c '{"function":"QueryAsset","Args":["user1"]}'
     ```

73. **MonitorTraffic**:
   - **وظیفه کلی**: مانیتورینگ ترافیک شبکه.
   - **ساختار داده**:
     ```json
     {
       "networkID": "string",
       "traffic": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **RecordTraffic(networkID: string, traffic: string) -> error**:
       - **ورودی**: networkID، traffic.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت ترافیک شبکه.
     - **QueryAsset(networkID: string) -> TrafficRecord**:
       - **خروجی**: JSON ساختار TrafficRecord.
       - **سناریو**: بررسی ترافیک.
     - **QueryAllAssets() -> []TrafficRecord**:
       - **خروجی**: لیست تمام ترافیک‌ها.
       - **سناریو**: نمایش برای Network Map.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C PerformanceChannel -n MonitorTraffic -c '{"function":"RecordTraffic","Args":["network1","500MB"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C PerformanceChannel -n MonitorTraffic -c '{"function":"QueryAsset","Args":["network1"]}'
     ```

74. **MonitorInterference**:
   - **وظیفه کلی**: مانیتورینگ سطح تداخل شبکه.
   - **ساختار داده**:
     ```json
     {
       "networkID": "string",
       "interferenceLevel": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **RecordInterference(networkID: string, interferenceLevel: string) -> error**:
       - **ورودی**: networkID، interferenceLevel.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت سطح تداخل.
     - **QueryAsset(networkID: string) -> InterferenceRecord**:
       - **خروجی**: JSON ساختار InterferenceRecord.
       - **سناریو**: بررسی تداخل.
     - **QueryAllAssets() -> []InterferenceRecord**:
       - **خروجی**: لیست تمام تداخل‌ها.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C PerformanceChannel -n MonitorInterference -c '{"function":"RecordInterference","Args":["network1","Low"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C PerformanceChannel -n MonitorInterference -c '{"function":"QueryAsset","Args":["network1"]}'
     ```

75. **MonitorResourceUsage**:
   - **وظیفه کلی**: مانیتورینگ استفاده از منابع.
   - **ساختار داده**:
     ```json
     {
       "entityID": "string",
       "resource": "string",
       "amount": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **RecordUsage(entityID: string, resource: string, amount: string) -> error**:
       - **ورودی**: entityID، resource، amount.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت استفاده از منابع.
     - **QueryAsset(entityID: string) -> ResourceUsageRecord**:
       - **خروجی**: JSON ساختار ResourceUsageRecord.
       - **سناریو**: بررسی استفاده از منابع.
     - **QueryAllAssets() -> []ResourceUsageRecord**:
       - **خروجی**: لیست تمام استفاده‌ها.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C ResourceChannel -n MonitorResourceUsage -c '{"function":"RecordUsage","Args":["entity1","Bandwidth","100Mbps"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C ResourceChannel -n MonitorResourceUsage -c '{"function":"QueryAsset","Args":["entity1"]}'
     ```

76. **LogSecurityEvent**:
   - **وظیفه کلی**: ثبت رویدادهای امنیتی.
   - **ساختار داده**:
     ```json
     {
       "entityID": "string",
       "event": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Log(entityID: string, event: string) -> error**:
       - **ورودی**: entityID، event.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت رویداد امنیتی.
     - **QueryAsset(entityID: string) -> SecurityEventLog**:
       - **خروجی**: JSON ساختار SecurityEventLog.
       - **سناریو**: بررسی رویداد.
     - **QueryAllAssets() -> []SecurityEventLog**:
       - **خروجی**: لیست تمام رویدادها.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C SecurityChannel -n LogSecurityEvent -c '{"function":"Log","Args":["entity1","UnauthorizedAccess"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C SecurityChannel -n LogSecurityEvent -c '{"function":"QueryAsset","Args":["entity1"]}'
     ```

77. **LogAccessControl**:
   - **وظیفه کلی**: ثبت کنترل دسترسی.
   - **ساختار داده**:
     ```json
     {
       "entityID": "string",
       "action": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Log(entityID: string, action: string) -> error**:
       - **ورودی**: entityID، action.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت کنترل دسترسی.
     - **QueryAsset(entityID: string) -> AccessControlLog**:
       - **خروجی**: JSON ساختار AccessControlLog.
       - **سناریو**: بررسی کنترل دسترسی.
     - **QueryAllAssets() -> []AccessControlLog**:
       - **خروجی**: لیست تمام کنترل‌های دسترسی.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C SecurityChannel -n LogAccessControl -c '{"function":"Log","Args":["entity1","AccessGranted"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C SecurityChannel -n LogAccessControl -c '{"function":"QueryAsset","Args":["entity1"]}'
     ```
     # توضیحات قراردادهای هوشمند پروژه 6G Fabric Network - بخش 10

این فایل توضیحات جامع قراردادهای 78 تا 85 (از 85 قرارداد هوشمند) را ارائه می‌دهد. هر قرارداد شامل وظیفه کلی، ساختار داده، توابع (با ورودی/خروجی و سناریوی استفاده)، و مثال دستورات invoke/query است.

## قراردادهای ممیزی

78. **LogNetworkAudit**:
   - **وظیفه کلی**: ثبت ممیزی شبکه.
   - **ساختار داده**:
     ```json
     {
       "networkID": "string",
       "action": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Log(networkID: string, action: string) -> error**:
       - **ورودی**: networkID، action.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت ممیزی شبکه.
     - **QueryAsset(networkID: string) -> NetworkAuditLog**:
       - **خروجی**: JSON ساختار NetworkAuditLog.
       - **سناریو**: بررسی ممیزی.
     - **QueryAllAssets() -> []NetworkAuditLog**:
       - **خروجی**: لیست تمام ممیزی‌ها.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C AuditChannel -n LogNetworkAudit -c '{"function":"Log","Args":["network1","StatusUpdate"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C AuditChannel -n LogNetworkAudit -c '{"function":"QueryAsset","Args":["network1"]}'
     ```

79. **LogAntennaAudit**:
   - **وظیفه کلی**: ثبت ممیزی آنتن‌ها.
   - **ساختار داده**:
     ```json
     {
       "antennaID": "string",
       "action": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Log(antennaID: string, action: string) -> error**:
       - **ورودی**: antennaID، action.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت ممیزی آنتن.
     - **QueryAsset(antennaID: string) -> AntennaAuditLog**:
       - **خروجی**: JSON ساختار AntennaAuditLog.
       - **سناریو**: بررسی ممیزی.
     - **QueryAllAssets() -> []AntennaAuditLog**:
       - **خروجی**: لیست تمام ممیزی‌ها.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C AuditChannel -n LogAntennaAudit -c '{"function":"Log","Args":["Antenna1","ConfigurationUpdate"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C AuditChannel -n LogAntennaAudit -c '{"function":"QueryAsset","Args":["Antenna1"]}'
     ```

80. **LogIoTAudit**:
   - **وظیفه کلی**: ثبت ممیزی دستگاه‌های IoT.
   - **ساختار داده**:
     ```json
     {
       "deviceID": "string",
       "action": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Log(deviceID: string, action: string) -> error**:
       - **ورودی**: deviceID، action.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت ممیزی دستگاه IoT.
     - **QueryAsset(deviceID: string) -> IoTAuditLog**:
       - **خروجی**: JSON ساختار IoTAuditLog.
       - **سناریو**: بررسی ممیزی.
     - **QueryAllAssets() -> []IoTAuditLog**:
       - **خروجی**: لیست تمام ممیزی‌ها.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C AuditChannel -n LogIoTAudit -c '{"function":"Log","Args":["iot1","StatusUpdate"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C AuditChannel -n LogIoTAudit -c '{"function":"QueryAsset","Args":["iot1"]}'
     ```

81. **LogUserAudit**:
   - **وظیفه کلی**: ثبت ممیزی کاربران.
   - **ساختار داده**:
     ```json
     {
       "userID": "string",
       "action": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Log(userID: string, action: string) -> error**:
       - **ورودی**: userID، action.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت ممیزی کاربر.
     - **QueryAsset(userID: string) -> UserAuditLog**:
       - **خروجی**: JSON ساختار UserAuditLog.
       - **سناریو**: بررسی ممیزی.
     - **QueryAllAssets() -> []UserAuditLog**:
       - **خروجی**: لیست تمام ممیزی‌ها.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C AuditChannel -n LogUserAudit -c '{"function":"Log","Args":["user1","LoginAttempt"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C AuditChannel -n LogUserAudit -c '{"function":"QueryAsset","Args":["user1"]}'
     ```

82. **LogPolicyChange**:
   - **وظیفه کلی**: ثبت تغییرات سیاست‌های شبکه.
   - **ساختار داده**:
     ```json
     {
       "policyID": "string",
       "change": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Log(policyID: string, change: string) -> error**:
       - **ورودی**: policyID، change.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت تغییر سیاست.
     - **QueryAsset(policyID: string) -> PolicyChangeLog**:
       - **خروجی**: JSON ساختار PolicyChangeLog.
       - **سناریو**: بررسی تغییر.
     - **QueryAllAssets() -> []PolicyChangeLog**:
       - **خروجی**: لیست تمام تغییرات.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C AuditChannel -n LogPolicyChange -c '{"function":"Log","Args":["policy1","PolicyUpdated"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C AuditChannel -n LogPolicyChange -c '{"function":"QueryAsset","Args":["policy1"]}'
     ```

83. **LogAccessAudit**:
   - **وظیفه کلی**: ثبت ممیزی دسترسی‌ها.
   - **ساختار داده**:
     ```json
     {
       "entityID": "string",
       "action": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Log(entityID: string, action: string) -> error**:
       - **ورودی**: entityID، action.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت ممیزی دسترسی.
     - **QueryAsset(entityID: string) -> AccessAuditLog**:
       - **خروجی**: JSON ساختار AccessAuditLog.
       - **سناریو**: بررسی ممیزی.
     - **QueryAllAssets() -> []AccessAuditLog**:
       - **خروجی**: لیست تمام ممیزی‌ها.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C AuditChannel -n LogAccessAudit -c '{"function":"Log","Args":["entity1","AccessGranted"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C AuditChannel -n LogAccessAudit -c '{"function":"QueryAsset","Args":["entity1"]}'
     ```

84. **LogPerformanceAudit**:
   - **وظیفه کلی**: ثبت ممیزی عملکرد.
   - **ساختار داده**:
     ```json
     {
       "entityID": "string",
       "metric": "string",
       "value": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Log(entityID: string, metric: string, value: string) -> error**:
       - **ورودی**: entityID، metric، value.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت ممیزی عملکرد.
     - **QueryAsset(entityID: string) -> PerformanceAuditLog**:
       - **خروجی**: JSON ساختار PerformanceAuditLog.
       - **سناریو**: بررسی ممیزی عملکرد.
     - **QueryAllAssets() -> []PerformanceAuditLog**:
       - **خروجی**: لیست تمام ممیزی‌های عملکرد.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C AuditChannel -n LogPerformanceAudit -c '{"function":"Log","Args":["entity1","Latency","50ms"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C AuditChannel -n LogPerformanceAudit -c '{"function":"QueryAsset","Args":["entity1"]}'
     ```

85. **LogComplianceAudit**:
   - **وظیفه کلی**: ثبت ممیزی انطباق.
   - **ساختار داده**:
     ```json
     {
       "entityID": "string",
       "complianceStatus": "string",
       "timestamp": "string"
     }
     ```
   - **توابع**:
     - **Log(entityID: string, complianceStatus: string) -> error**:
       - **ورودی**: entityID، complianceStatus.
       - **خروجی**: nil یا خطا.
       - **سناریو**: ثبت ممیزی انطباق.
     - **QueryAsset(entityID: string) -> ComplianceAuditLog**:
       - **خروجی**: JSON ساختار ComplianceAuditLog.
       - **سناریو**: بررسی ممیزی انطباق.
     - **QueryAllAssets() -> []ComplianceAuditLog**:
       - **خروجی**: لیست تمام ممیزی‌های انطباق.
       - **سناریو**: نمایش برای ممیزی.
   - **مثال دستورات**:
     ```bash
     peer chaincode invoke -C AuditChannel -n LogComplianceAudit -c '{"function":"Log","Args":["entity1","Compliant"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
     peer chaincode query -C AuditChannel -n LogComplianceAudit -c '{"function":"QueryAsset","Args":["entity1"]}'
     ```
