# توضیحات کامل قراردادهای هوشمند پروژه 6G Fabric Network

این فایل توضیحات کامل هر قرارداد هوشمند (85 قرارداد) را شامل می‌شود. هر قرارداد شامل توضیح وظیفه کلی، ساختار داده، توابع (با توضیح وظیفه هر تابع)، و مثال دستورات invoke و query است.

## قراردادهای مرتبط با موقعیت (35 قرارداد)

 1. **LocationBasedAssignment**:

    - **وظیفه کلی**: تخصیص آنتن به کاربر یا دستگاه IoT بر اساس فاصله از نقطه مرجع تصادفی.
    - **ساختار داده**: Assignment {EntityID: string, AntennaID: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - AssignAntenna(entityID, antennaID, x, y): آنتن را با محاسبه فاصله تخصیص می‌دهد.
      - QueryAntennaAssignment(entityID): اطلاعات تخصیص را برمی‌گرداند.
      - UpdateAntennaAssignment(entityID, newAntennaID, x, y): تخصیص را به‌روزرسانی می‌کند.
      - DeleteAntennaAssignment(entityID): تخصیص را حذف می‌کند.
      - ValidateDistance(entityID, antennaID, maxDistance): صحت فاصله را بررسی می‌کند.
      - GetAssignmentHistory(entityID): تاریخچه تخصیص را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C GeneralOperationsChannel -n LocationBasedAssignment -c '{"function":"AssignAntenna","Args":["user1","Antenna1","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C GeneralOperationsChannel -n LocationBasedAssignment -c '{"function":"QueryAntennaAssignment","Args":["user1"]}'
      ```

 2. **LocationBasedConnection**:

    - **وظیفه کلی**: مدیریت اتصال کاربر یا دستگاه به آنتن بر اساس فاصله.
    - **ساختار داده**: Connection {EntityID: string, AntennaID: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - ConnectEntity(entityID, antennaID, x, y): اتصال را با محاسبه فاصله ثبت می‌کند.
      - QueryConnection(entityID): وضعیت اتصال را برمی‌گرداند.
      - UpdateConnection(entityID, newAntennaID, x, y): اتصال را به‌روزرسانی می‌کند.
      - DisconnectEntity(entityID): اتصال را قطع می‌کند.
      - ValidateConnectionDistance(entityID, antennaID, maxDistance): صحت فاصله اتصال را بررسی می‌کند.
      - GetConnectionHistory(entityID): تاریخچه اتصال را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C ConnectivityChannel -n LocationBasedConnection -c '{"function":"ConnectEntity","Args":["user1","Antenna1","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C ConnectivityChannel -n LocationBasedConnection -c '{"function":"QueryConnection","Args":["user1"]}'
      ```

 3. **LocationBasedBandwidth**:

    - **وظیفه کلی**: تخصیص پهنای باند بر اساس فاصله.
    - **ساختار داده**: Bandwidth {EntityID: string, AntennaID: string, Amount: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - AllocateBandwidth(entityID, antennaID, amount, x, y): پهنای باند را با محاسبه فاصله تخصیص می‌دهد.
      - QueryBandwidth(entityID): پهنای باند را برمی‌گرداند.
      - AdjustBandwidth(entityID, newAmount): مقدار پهنای باند را تنظیم می‌کند.
      - ReleaseBandwidth(entityID): تخصیص پهنای باند را آزاد می‌کند.
      - ValidateBandwidthDistance(entityID, antennaID, maxDistance): صحت فاصله را بررسی می‌کند.
      - GetBandwidthHistory(entityID): تاریخچه تخصیص را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C ResourceChannel -n LocationBasedBandwidth -c '{"function":"AllocateBandwidth","Args":["user1","Antenna1","100","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C ResourceChannel -n LocationBasedBandwidth -c '{"function":"QueryBandwidth","Args":["user1"]}'
      ```

 4. **LocationBasedQoS**:

    - **وظیفه کلی**: مدیریت کیفیت سرویس بر اساس فاصله.
    - **ساختار داده**: QoS {EntityID: string, QoSLevel: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - SetQoS(entityID, qosLevel, x, y): سطح QoS را با محاسبه فاصله تنظیم می‌کند.
      - QueryQoS(entityID): سطح QoS را برمی‌گرداند.
      - UpdateQoS(entityID, newQoSLevel): سطح QoS را به‌روزرسانی می‌کند.
      - ValidateQoSDistance(entityID, qosLevel, maxDistance): صحت فاصله را بررسی می‌کند.
      - GetQoSHistory(entityID): تاریخچه QoS را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C PerformanceChannel -n LocationBasedQoS -c '{"function":"SetQoS","Args":["user1","High","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C PerformanceChannel -n LocationBasedQoS -c '{"function":"QueryQoS","Args":["user1"]}'
      ```

 5. **LocationBasedPriority**:

    - **وظیفه کلی**: تخصیص اولویت بر اساس فاصله.
    - **ساختار داده**: Priority {EntityID: string, Priority: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - AssignPriority(entityID, priority, x, y): اولویت را با محاسبه فاصله تنظیم می‌کند.
      - QueryPriority(entityID): اولویت را برمی‌گرداند.
      - UpdatePriority(entityID, newPriority): اولویت را به‌روزرسانی می‌کند.
      - ValidatePriorityDistance(entityID, priority, maxDistance): صحت فاصله را بررسی می‌کند.
      - GetPriorityHistory(entityID): تاریخچه اولویت را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C PolicyChannel -n LocationBasedPriority -c '{"function":"AssignPriority","Args":["user1","Urgent","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C PolicyChannel -n LocationBasedPriority -c '{"function":"QueryPriority","Args":["user1"]}'
      ```

 6. **LocationBasedStatus**:

    - **وظیفه کلی**: نظارت بر وضعیت اتصال بر اساس فاصله.
    - **ساختار داده**: Status {EntityID: string, Status: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - UpdateStatus(entityID, status, x, y): وضعیت را با محاسبه فاصله به‌روزرسانی می‌کند.
      - QueryStatus(entityID): وضعیت را برمی‌گرداند.
      - LogStatusHistory(entityID): تاریخچه وضعیت را ثبت می‌کند.
      - ValidateStatusDistance(entityID, status, maxDistance): صحت فاصله را بررسی می‌کند.
      - GetStatusHistory(entityID): تاریخچه وضعیت را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C ConnectivityChannel -n LocationBasedStatus -c '{"function":"UpdateStatus","Args":["user1","Active","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C ConnectivityChannel -n LocationBasedStatus -c '{"function":"QueryStatus","Args":["user1"]}'
      ```

 7. **LocationBasedFault**:

    - **وظیفه کلی**: تشخیص خطاها بر اساس فاصله.
    - **ساختار داده**: Fault {EntityID: string, Fault: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - DetectFault(entityID, fault, x, y): خطا را با محاسبه فاصله ثبت می‌کند.
      - QueryFault(entityID): جزئیات خطا را برمی‌گرداند.
      - ResolveFault(entityID): خطا را رفع می‌کند.
      - LogFaultHistory(entityID): تاریخچه خطاها را ثبت می‌کند.
      - ValidateFaultDistance(entityID, fault, maxDistance): صحت فاصله را بررسی می‌کند.
      - GetFaultHistory(entityID): تاریخچه خطاها را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C AuditChannel -n LocationBasedFault -c '{"function":"DetectFault","Args":["user1","ConnectionLost","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C AuditChannel -n LocationBasedFault -c '{"function":"QueryFault","Args":["user1"]}'
      ```

 8. **LocationBasedTraffic**:

    - **وظیفه کلی**: نظارت بر ترافیک شبکه بر اساس فاصله.
    - **ساختار داده**: Traffic {EntityID: string, TrafficLevel: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - MonitorTraffic(entityID, trafficLevel, x, y): ترافیک را با محاسبه فاصله ثبت می‌کند.
      - QueryTraffic(entityID): اطلاعات ترافیک را برمی‌گرداند.
      - AdjustTraffic(entityID, newTrafficLevel): سطح ترافیک را تنظیم می‌کند.
      - GetTrafficHistory(entityID): تاریخچه ترافیک را برمی‌گرداند.
      - ValidateTrafficDistance(entityID, trafficLevel, maxDistance): صحت فاصله را بررسی می‌کند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C PerformanceChannel -n LocationBasedTraffic -c '{"function":"MonitorTraffic","Args":["user1","High","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C PerformanceChannel -n LocationBasedTraffic -c '{"function":"QueryTraffic","Args":["user1"]}'
      ```

 9. **LocationBasedLatency**:

    - **وظیفه کلی**: ردیابی تأخیر شبکه بر اساس فاصله.
    - **ساختار داده**: Latency {EntityID: string, Latency: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - TrackLatency(entityID, latency, x, y): تأخیر را با محاسبه فاصله ثبت می‌کند.
      - QueryLatency(entityID): تأخیر را برمی‌گرداند.
      - UpdateLatency(entityID, newLatency): تأخیر را به‌روزرسانی می‌کند.
      - ValidateLatencyDistance(entityID, latency, maxDistance): صحت فاصله را بررسی می‌کند.
      - GetLatencyHistory(entityID): تاریخچه تأخیر را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C PerformanceChannel -n LocationBasedLatency -c '{"function":"TrackLatency","Args":["user1","10ms","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C PerformanceChannel -n LocationBasedLatency -c '{"function":"QueryLatency","Args":["user1"]}'
      ```

10. **LocationBasedEnergy**:

    - **وظیفه کلی**: نظارت بر مصرف انرژی بر اساس فاصله.
    - **ساختار داده**: Energy {EntityID: string, Energy: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - MonitorEnergy(entityID, energy, x, y): مصرف انرژی را با محاسبه فاصله ثبت می‌کند.
      - QueryEnergy(entityID): مصرف را برمی‌گرداند.
      - OptimizeEnergy(entityID, targetEnergy): مصرف انرژی را بهینه می‌کند.
      - GetEnergyHistory(entityID): تاریخچه مصرف انرژی را برمی‌گرداند.
      - ValidateEnergyDistance(entityID, energy, maxDistance): صحت فاصله را بررسی می‌کند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C PerformanceChannel -n LocationBasedEnergy -c '{"function":"MonitorEnergy","Args":["user1","50W","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C PerformanceChannel -n LocationBasedEnergy -c '{"function":"QueryEnergy","Args":["user1"]}'
      ```

11. **LocationBasedRoaming**:

    - **وظیفه کلی**: مدیریت رومینگ بر اساس فاصله.
    - **ساختار داده**: Roaming {EntityID: string, FromAntenna: string, ToAntenna: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - PerformRoaming(entityID, fromAntenna, toAntenna, x, y): رومینگ را با محاسبه فاصله ثبت می‌کند.
      - QueryRoaming(entityID): جزئیات رومینگ را برمی‌گرداند.
      - ValidateRoamingDistance(entityID, fromAntenna, toAntenna, maxDistance): صحت فاصله را بررسی می‌کند.
      - LogRoamingHistory(entityID): تاریخچه رومینگ را ثبت می‌کند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C ConnectivityChannel -n LocationBasedRoaming -c '{"function":"PerformRoaming","Args":["user1","Antenna1","Antenna2","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C ConnectivityChannel -n LocationBasedRoaming -c '{"function":"QueryRoaming","Args":["user1"]}'
      ```

12. **LocationBasedSignalStrength**:

    - **وظیفه کلی**: نظارت بر قدرت سیگنال بر اساس فاصله.
    - **ساختار داده**: Signal {EntityID: string, SignalStrength: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - MonitorSignalStrength(entityID, signalStrength, x, y): قدرت سیگنال را با محاسبه فاصله ثبت می‌کند.
      - QuerySignalStrength(entityID): قدرت سیگنال را برمی‌گرداند.
      - AdjustSignalStrength(entityID, newSignalStrength): قدرت سیگنال را تنظیم می‌کند.
      - GetSignalHistory(entityID): تاریخچه قدرت سیگنال را برمی‌گرداند.
      - ValidateSignalDistance(entityID, signalStrength, maxDistance): صحت فاصله را بررسی می‌کند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C PerformanceChannel -n LocationBasedSignalStrength -c '{"function":"MonitorSignalStrength","Args":["user1","Strong","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C PerformanceChannel -n LocationBasedSignalStrength -c '{"function":"QuerySignalStrength","Args":["user1"]}'
      ```

13. **LocationBasedCoverage**:

    - **وظیفه کلی**: مدیریت پوشش شبکه بر اساس فاصله.
    - **ساختار داده**: Coverage {EntityID: string, CoverageLevel: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - SetCoverage(entityID, coverageLevel, x, y): سطح پوشش را با محاسبه فاصله تنظیم می‌کند.
      - QueryCoverage(entityID): سطح پوشش را برمی‌گرداند.
      - UpdateCoverage(entityID, newCoverageLevel): پوشش را به‌روزرسانی می‌کند.
      - ValidateCoverageDistance(entityID, coverageLevel, maxDistance): صحت فاصله را بررسی می‌کند.
      - GetCoverageHistory(entityID): تاریخچه پوشش را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C PerformanceChannel -n LocationBasedCoverage -c '{"function":"SetCoverage","Args":["user1","Full","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C PerformanceChannel -n LocationBasedCoverage -c '{"function":"QueryCoverage","Args":["user1"]}'
      ```

14. **LocationBasedInterference**:

    - **وظیفه کلی**: تشخیص تداخل سیگنال بر اساس فاصله.
    - **ساختار داده**: Interference {EntityID: string, InterferenceLevel: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - DetectInterference(entityID, interferenceLevel, x, y): تداخل را با محاسبه فاصله ثبت می‌کند.
      - QueryInterference(entityID): سطح تداخل را برمی‌گرداند.
      - MitigateInterference(entityID): تداخل را کاهش می‌دهد.
      - LogInterferenceHistory(entityID): تاریخچه تداخل را ثبت می‌کند.
      - ValidateInterferenceDistance(entityID, interferenceLevel, maxDistance): صحت فاصله را بررسی می‌کند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C PerformanceChannel -n LocationBasedInterference -c '{"function":"DetectInterference","Args":["user1","High","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C PerformanceChannel -n LocationBasedInterference -c '{"function":"QueryInterference","Args":["user1"]}'
      ```

15. **LocationBasedResourceAllocation**:

    - **وظیفه کلی**: تخصیص منابع بر اساس فاصله.
    - **ساختار داده**: Resource {EntityID: string, ResourceID: string, Amount: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - AllocateResource(entityID, resourceID, amount, x, y): منبع را با محاسبه فاصله تخصیص می‌دهد.
      - QueryResource(entityID): تخصیص را برمی‌گرداند.
      - ReleaseResource(entityID, resourceID): تخصیص منبع را آزاد می‌کند.
      - ValidateResourceDistance(entityID, resourceID, maxDistance): صحت فاصله را بررسی می‌کند.
      - GetResourceHistory(entityID): تاریخچه تخصیص را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C ResourceChannel -n LocationBasedResourceAllocation -c '{"function":"AllocateResource","Args":["user1","resource1","100","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C ResourceChannel -n LocationBasedResourceAllocation -c '{"function":"QueryResource","Args":["user1"]}'
      ```

16. **LocationBasedNetworkLoad**:

    - **وظیفه کلی**: نظارت بر بار شبکه بر اساس فاصله.
    - **ساختار داده**: NetworkLoad {EntityID: string, Load: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - MonitorNetworkLoad(entityID, load, x, y): بار شبکه را با محاسبه فاصله ثبت می‌کند.
      - QueryNetworkLoad(entityID): بار را برمی‌گرداند.
      - AdjustNetworkLoad(entityID, newLoad): بار شبکه را تنظیم می‌کند.
      - ValidateNetworkLoadDistance(entityID, load, maxDistance): صحت فاصله را بررسی می‌کند.
      - GetNetworkLoadHistory(entityID): تاریخچه بار شبکه را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C PerformanceChannel -n LocationBasedNetworkLoad -c '{"function":"MonitorNetworkLoad","Args":["user1","High","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C PerformanceChannel -n LocationBasedNetworkLoad -c '{"function":"QueryNetworkLoad","Args":["user1"]}'
      ```

17. **LocationBasedCongestion**:

    - **وظیفه کلی**: مدیریت ازدحام شبکه بر اساس فاصله.
    - **ساختار داده**: Congestion {EntityID: string, CongestionLevel: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - ManageCongestion(entityID, congestionLevel, x, y): ازدحام را با محاسبه فاصله ثبت می‌کند.
      - QueryCongestion(entityID): سطح ازدحام را برمی‌گرداند.
      - MitigateCongestion(entityID): ازدحام را کاهش می‌دهد.
      - ValidateCongestionDistance(entityID, congestionLevel, maxDistance): صحت فاصله را بررسی می‌کند.
      - LogCongestionHistory(entityID): تاریخچه ازدحام را ثبت می‌کند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C PerformanceChannel -n LocationBasedCongestion -c '{"function":"ManageCongestion","Args":["user1","Severe","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C PerformanceChannel -n LocationBasedCongestion -c '{"function":"QueryCongestion","Args":["user1"]}'
      ```

18. **LocationBasedDynamicRouting**:

    - **وظیفه کلی**: مدیریت مسیریابی پویا بر اساس فاصله.
    - **ساختار داده**: Routing {EntityID: string, RouteID: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - SetRouting(entityID, routeID, x, y): مسیر را با محاسبه فاصله تنظیم می‌کند.
      - QueryRouting(entityID): مسیر را برمی‌گرداند.
      - UpdateRouting(entityID, newRouteID): مسیر را به‌روزرسانی می‌کند.
      - ValidateRoutingDistance(entityID, routeID, maxDistance): صحت فاصله را بررسی می‌کند.
      - GetRoutingHistory(entityID): تاریخچه مسیریابی را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C ConnectivityChannel -n LocationBasedDynamicRouting -c '{"function":"SetRouting","Args":["user1","route1","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C ConnectivityChannel -n LocationBasedDynamicRouting -c '{"function":"QueryRouting","Args":["user1"]}'
      ```

19. **LocationBasedAntennaConfig**:

    - **وظیفه کلی**: پیکربندی آنتن‌ها بر اساس فاصله.
    - **ساختار داده**: AntennaConfig {AntennaID: string, Config: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - ConfigureAntenna(antennaID, config, x, y): پیکربندی را با محاسبه فاصله ثبت می‌کند.
      - QueryAntennaConfig(antennaID): پیکربندی را برمی‌گرداند.
      - UpdateAntennaConfig(antennaID, newConfig): پیکربندی را به‌روزرسانی می‌کند.
      - ValidateAntennaConfigDistance(antennaID, config, maxDistance): صحت فاصله را بررسی می‌کند.
      - GetAntennaConfigHistory(antennaID): تاریخچه پیکربندی را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C GeneralOperationsChannel -n LocationBasedAntennaConfig -c '{"function":"ConfigureAntenna","Args":["Antenna1","Config1","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C GeneralOperationsChannel -n LocationBasedAntennaConfig -c '{"function":"QueryAntennaConfig","Args":["Antenna1"]}'
      ```

20. **LocationBasedSignalQuality**:

    - **وظیفه کلی**: نظارت بر کیفیت سیگنال بر اساس فاصله.
    - **ساختار داده**: SignalQuality {EntityID: string, Quality: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - MonitorSignalQuality(entityID, quality, x, y): کیفیت را با محاسبه فاصله ثبت می‌کند.
      - QuerySignalQuality(entityID): کیفیت را برمی‌گرداند.
      - AdjustSignalQuality(entityID, newQuality): کیفیت سیگنال را تنظیم می‌کند.
      - ValidateSignalQualityDistance(entityID, quality, maxDistance): صحت فاصله را بررسی می‌کند.
      - GetSignalQualityHistory(entityID): تاریخچه کیفیت سیگنال را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C PerformanceChannel -n LocationBasedSignalQuality -c '{"function":"MonitorSignalQuality","Args":["user1","Excellent","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C PerformanceChannel -n LocationBasedSignalQuality -c '{"function":"QuerySignalQuality","Args":["user1"]}'
      ```

21. **LocationBasedNetworkHealth**:

    - **وظیفه کلی**: بررسی سلامت شبکه بر اساس فاصله.
    - **ساختار داده**: NetworkHealth {EntityID: string, HealthStatus: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - MonitorNetworkHealth(entityID, healthStatus, x, y): سلامت را با محاسبه فاصله ثبت می‌کند.
      - QueryNetworkHealth(entityID): سلامت را برمی‌گرداند.
      - UpdateNetworkHealth(entityID, newHealthStatus): سلامت شبکه را به‌روزرسانی می‌کند.
      - ValidateNetworkHealthDistance(entityID, healthStatus, maxDistance): صحت فاصله را بررسی می‌کند.
      - GetNetworkHealthHistory(entityID): تاریخچه سلامت را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C PerformanceChannel -n LocationBasedNetworkHealth -c '{"function":"MonitorNetworkHealth","Args":["user1","Stable","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C PerformanceChannel -n LocationBasedNetworkHealth -c '{"function":"QueryNetworkHealth","Args":["user1"]}'
      ```

22. **LocationBasedPowerManagement**:

    - **وظیفه کلی**: مدیریت توان بر اساس فاصله.
    - **ساختار داده**: Power {EntityID: string, PowerLevel: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - ManagePower(entityID, powerLevel, x, y): توان را با محاسبه فاصله تنظیم می‌کند.
      - QueryPower(entityID): سطح توان را برمی‌گرداند.
      - OptimizePower(entityID, targetPower): توان را بهینه می‌کند.
      - ValidatePowerDistance(entityID, powerLevel, maxDistance): صحت فاصله را بررسی می‌کند.
      - GetPowerHistory(entityID): تاریخچه توان را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C PerformanceChannel -n LocationBasedPowerManagement -c '{"function":"ManagePower","Args":["user1","Low","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C PerformanceChannel -n LocationBasedPowerManagement -c '{"function":"QueryPower","Args":["user1"]}'
      ```

23. **LocationBasedChannelAllocation**:

    - **وظیفه کلی**: تخصیص کانال‌های ارتباطی بر اساس فاصله.
    - **ساختار داده**: Channel {EntityID: string, ChannelID: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - AllocateChannel(entityID, channelID, x, y): کانال را با محاسبه فاصله تخصیص می‌دهد.
      - QueryChannel(entityID): کانال را برمی‌گرداند.
      - ReleaseChannel(entityID, channelID): کانال را آزاد می‌کند.
      - ValidateChannelDistance(entityID, channelID, maxDistance): صحت فاصله را بررسی می‌کند.
      - GetChannelHistory(entityID): تاریخچه تخصیص را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C ConnectivityChannel -n LocationBasedChannelAllocation -c '{"function":"AllocateChannel","Args":["user1","channel1","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C ConnectivityChannel -n LocationBasedChannelAllocation -c '{"function":"QueryChannel","Args":["user1"]}'
      ```

24. **LocationBasedSessionManagement**:

    - **وظیفه کلی**: مدیریت جلسات کاربران یا دستگاه‌ها بر اساس فاصله.
    - **ساختار داده**: Session {EntityID: string, SessionID: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - ManageSession(entityID, sessionID, x, y): جلسه را با محاسبه فاصله ثبت می‌کند.
      - QuerySession(entityID): جزئیات جلسه را برمی‌گرداند.
      - EndSession(entityID, sessionID): جلسه را پایان می‌دهد.
      - ValidateSessionDistance(entityID, sessionID, maxDistance): صحت فاصله را بررسی می‌کند.
      - GetSessionHistory(entityID): تاریخچه جلسات را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C SessionChannel -n LocationBasedSessionManagement -c '{"function":"ManageSession","Args":["user1","session1","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C SessionChannel -n LocationBasedSessionManagement -c '{"function":"QuerySession","Args":["user1"]}'
      ```

25. **LocationBasedIoTConnection**:

    - **وظیفه کلی**: اتصال دستگاه‌های IoT بر اساس فاصله.
    - **ساختار داده**: IoTConnection {IoTID: string, AntennaID: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - ConnectIoT(iotID, antennaID, x, y): اتصال را با محاسبه فاصله ثبت می‌کند.
      - QueryIoTConnection(iotID): وضعیت اتصال را برمی‌گرداند.
      - UpdateIoTConnection(iotID, newAntennaID, x, y): اتصال را به‌روزرسانی می‌کند.
      - DisconnectIoT(iotID): اتصال را قطع می‌کند.
      - ValidateIoTConnectionDistance(iotID, antennaID, maxDistance): صحت فاصله را بررسی می‌کند.
      - GetIoTConnectionHistory(iotID): تاریخچه اتصال را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C IoTChannel -n LocationBasedIoTConnection -c '{"function":"ConnectIoT","Args":["iot1","Antenna1","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C IoTChannel -n LocationBasedIoTConnection -c '{"function":"QueryIoTConnection","Args":["iot1"]}'
      ```

26. **LocationBasedIoTBandwidth**:

    - **وظیفه کلی**: تخصیص پهنای باند به دستگاه‌های IoT بر اساس فاصله.
    - **ساختار داده**: IoTBandwidth {IoTID: string, Amount: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - AllocateIoTBandwidth(iotID, amount, x, y): پهنای باند را با محاسبه فاصله تخصیص می‌دهد.
      - QueryIoTBandwidth(iotID): پهنای باند را برمی‌گرداند.
      - AdjustIoTBandwidth(iotID, newAmount): پهنای باند را تنظیم می‌کند.
      - ValidateIoTBandwidthDistance(iotID, amount, maxDistance): صحت فاصله را بررسی می‌کند.
      - GetIoTBandwidthHistory(iotID): تاریخچه تخصیص را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C IoTChannel -n LocationBasedIoTBandwidth -c '{"function":"AllocateIoTBandwidth","Args":["iot1","100","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C IoTChannel -n LocationBasedIoTBandwidth -c '{"function":"QueryIoTBandwidth","Args":["iot1"]}'
      ```

27. **LocationBasedIoTStatus**:

    - **وظیفه کلی**: نظارت بر وضعیت دستگاه‌های IoT بر اساس فاصله.
    - **ساختار داده**: IoTStatus {IoTID: string, Status: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - UpdateIoTStatus(iotID, status, x, y): وضعیت را با محاسبه فاصله به‌روزرسانی می‌کند.
      - QueryIoTStatus(iotID): وضعیت را برمی‌گرداند.
      - LogIoTStatusHistory(iotID): تاریخچه وضعیت را ثبت می‌کند.
      - ValidateIoTStatusDistance(iotID, status, maxDistance): صحت فاصله را بررسی می‌کند.
      - GetIoTStatusHistory(iotID): تاریخچه وضعیت را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C IoTChannel -n LocationBasedIoTStatus -c '{"function":"UpdateIoTStatus","Args":["iot1","Active","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C IoTChannel -n LocationBasedIoTStatus -c '{"function":"QueryIoTStatus","Args":["iot1"]}'
      ```

28. **LocationBasedIoTFault**:

    - **وظیفه کلی**: تشخیص خطاها در دستگاه‌های IoT بر اساس فاصله.
    - **ساختار داده**: IoTFault {IoTID: string, Fault: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - DetectIoTFault(iotID, fault, x, y): خطا را با محاسبه فاصله ثبت می‌کند.
      - QueryIoTFault(iotID): جزئیات خطا را برمی‌گرداند.
      - ResolveIoTFault(iotID): خطا را رفع می‌کند.
      - ValidateIoTFaultDistance(iotID, fault, maxDistance): صحت فاصله را بررسی می‌کند.
      - GetIoTFaultHistory(iotID): تاریخچه خطاها را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C IoTChannel -n LocationBasedIoTFault -c '{"function":"DetectIoTFault","Args":["iot1","PowerFailure","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C IoTChannel -n LocationBasedIoTFault -c '{"function":"QueryIoTFault","Args":["iot1"]}'
      ```

29. **LocationBasedIoTSession**:

    - **وظیفه کلی**: مدیریت جلسات دستگاه‌های IoT بر اساس فاصله.
    - **ساختار داده**: IoTSession {IoTID: string, SessionID: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - TrackIoTSession(iotID, sessionID, x, y): جلسه را با محاسبه فاصله ثبت می‌کند.
      - QueryIoTSession(iotID): جزئیات جلسه را برمی‌گرداند.
      - EndIoTSession(iotID, sessionID): جلسه را پایان می‌دهد.
      - ValidateIoTSessionDistance(iotID, sessionID, maxDistance): صحت فاصله را بررسی می‌کند.
      - GetIoTSessionHistory(iotID): تاریخچه جلسات را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C IoTChannel -n LocationBasedIoTSession -c '{"function":"TrackIoTSession","Args":["iot1","session1","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C IoTChannel -n LocationBasedIoTSession -c '{"function":"QueryIoTSession","Args":["iot1"]}'
      ```

30. **LocationBasedIoTAuthentication**:

    - **وظیفه کلی**: احراز هویت دستگاه‌های IoT بر اساس فاصله.
    - **ساختار داده**: IoTAuth {IoTID: string, Token: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - AuthenticateIoT(iotID, token, x, y): توکن را با محاسبه فاصله ثبت می‌کند.
      - QueryIoTAuth(iotID): وضعیت احراز هویت را برمی‌گرداند.
      - RevokeIoTAuth(iotID): احراز هویت را لغو می‌کند.
      - ValidateIoTAuthDistance(iotID, token, maxDistance): صحت فاصله را بررسی می‌کند.
      - GetIoTAuthHistory(iotID): تاریخچه احراز هویت را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C IoTChannel -n LocationBasedIoTAuthentication -c '{"function":"AuthenticateIoT","Args":["iot1","token123","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C IoTChannel -n LocationBasedIoTAuthentication -c '{"function":"QueryIoTAuth","Args":["iot1"]}'
      ```

31. **LocationBasedIoTRegistration**:

    - **وظیفه کلی**: ثبت دستگاه‌های IoT بر اساس فاصله.
    - **ساختار داده**: IoTRegistration {IoTID: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - RegisterIoT(iotID, x, y): دستگاه IoT را با محاسبه فاصله ثبت می‌کند.
      - QueryIoTRegistration(iotID): وضعیت ثبت را برمی‌گرداند.
      - UpdateIoTRegistration(iotID, x, y): ثبت را به‌روزرسانی می‌کند.
      - ValidateIoTRegistrationDistance(iotID, maxDistance): صحت فاصله را بررسی می‌کند.
      - GetIoTRegistrationHistory(iotID): تاریخچه ثبت را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C IoTChannel -n LocationBasedIoTRegistration -c '{"function":"RegisterIoT","Args":["iot1","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C IoTChannel -n LocationBasedIoTRegistration -c '{"function":"QueryIoTRegistration","Args":["iot1"]}'
      ```

32. **LocationBasedIoTRevocation**:

    - **وظیفه کلی**: لغو دسترسی دستگاه‌های IoT بر اساس فاصله.
    - **ساختار داده**: IoTRevocation {IoTID: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - RevokeIoT(iotID, x, y): دسترسی دستگاه را با محاسبه فاصله لغو می‌کند.
      - QueryIoTRevocation(iotID): وضعیت لغو را برمی‌گرداند.
      - ReinstateIoT(iotID): دسترسی دستگاه را بازگردانی می‌کند.
      - ValidateIoTRevocationDistance(iotID, maxDistance): صحت فاصله را بررسی می‌کند.
      - GetIoTRevocationHistory(iotID): تاریخچه لغو را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C IoTChannel -n LocationBasedIoTRevocation -c '{"function":"RevokeIoT","Args":["iot1","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C IoTChannel -n LocationBasedIoTRevocation -c '{"function":"QueryIoTRevocation","Args":["iot1"]}'
      ```

33. **LocationBasedIoTResource**:

    - **وظیفه کلی**: درخواست منابع توسط دستگاه‌های IoT بر اساس فاصله.
    - **ساختار داده**: IoTResource {IoTID: string, ResourceID: string, Amount: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - RequestIoTResource(iotID, resourceID, amount, x, y): درخواست را با محاسبه فاصله ثبت می‌کند.
      - QueryIoTResource(iotID): جزئیات درخواست را برمی‌گرداند.
      - CancelIoTResource(iotID, resourceID): درخواست را لغو می‌کند.
      - ValidateIoTResourceDistance(iotID, resourceID, maxDistance): صحت فاصله را بررسی می‌کند.
      - GetIoTResourceHistory(iotID): تاریخچه درخواست را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C IoTChannel -n LocationBasedIoTResource -c '{"function":"RequestIoTResource","Args":["iot1","resource1","100","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C IoTChannel -n LocationBasedIoTResource -c '{"function":"QueryIoTResource","Args":["iot1"]}'
      ```

34. **LocationBasedNetworkPerformance**:

    - **وظیفه کلی**: ثبت معیارهای عملکرد شبکه بر اساس فاصله.
    - **ساختار داده**: NetworkPerformance {EntityID: string, Metric: string, Value: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - LogNetworkPerformance(entityID, metric, value, x, y): معیار عملکرد را با محاسبه فاصله ثبت می‌کند.
      - QueryNetworkPerformance(entityID): اطلاعات معیار را برمی‌گرداند.
      - ClearNetworkPerformance(entityID): معیارهای عملکرد را پاک می‌کند.
      - ValidateNetworkPerformanceDistance(entityID, metric, maxDistance): صحت فاصله را بررسی می‌کند.
      - GetNetworkPerformanceHistory(entityID): تاریخچه معیارهای عملکرد را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C PerformanceChannel -n LocationBasedNetworkPerformance -c '{"function":"LogNetworkPerformance","Args":["user1","TPS","100","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C PerformanceChannel -n LocationBasedNetworkPerformance -c '{"function":"QueryNetworkPerformance","Args":["user1"]}'
      ```

35. **LocationBasedUserActivity**:

    - **وظیفه کلی**: ثبت فعالیت‌های کاربران بر اساس فاصله.
    - **ساختار داده**: UserActivity {UserID: string, Action: string, X: string, Y: string, Distance: string, Timestamp: string}
    - **توابع**:
      - LogUserActivity(userID, action, x, y): فعالیت کاربر را با محاسبه فاصله ثبت می‌کند.
      - QueryUserActivity(userID): اطلاعات فعالیت را برمی‌گرداند.
      - ClearUserActivity(userID): فعالیت‌های کاربر را پاک می‌کند.
      - ValidateUserActivityDistance(userID, action, maxDistance): صحت فاصله را بررسی می‌کند.
      - GetUserActivityHistory(userID): تاریخچه فعالیت‌ها را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C AuditChannel -n LocationBasedUserActivity -c '{"function":"LogUserActivity","Args":["user1","Login","40.7128","-74.0060"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C AuditChannel -n LocationBasedUserActivity -c '{"function":"QueryUserActivity","Args":["user1"]}'
      ```

## قراردادهای عمومی (50 قرارداد)

 1. **AuthenticateUser**:

    - **وظیفه کلی**: احراز هویت کاربران برای دسترسی به شبکه 6G.
    - **ساختار داده**: Auth {UserID: string, Token: string, Timestamp: string}
    - **توابع**:
      - AuthenticateUser(userID, token): توکن کاربر را ثبت می‌کند.
      - QueryAuth(userID): وضعیت احراز هویت را برمی‌گرداند.
      - RevokeUserAuth(userID): احراز هویت را لغو می‌کند.
      - ValidateUserToken(userID, token): صحت توکن را بررسی می‌کند.
      - GetAuthHistory(userID): تاریخچه احراز هویت را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C SecurityChannel -n AuthenticateUser -c '{"function":"AuthenticateUser","Args":["user1","token123"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C SecurityChannel -n AuthenticateUser -c '{"function":"QueryAuth","Args":["user1"]}'
      ```

 2. **AuthenticateIoT**:

    - **وظیفه کلی**: احراز هویت دستگاه‌های IoT.
    - **ساختار داده**: AuthIoT {IoTID: string, Token: string, Timestamp: string}
    - **توابع**:
      - AuthenticateIoT(iotID, token): توکن دستگاه IoT را ثبت می‌کند.
      - QueryAuthIoT(iotID): وضعیت احراز هویت را برمی‌گرداند.
      - RevokeIoTAuth(iotID): احراز هویت را لغو می‌کند.
      - ValidateIoTToken(iotID, token): صحت توکن را بررسی می‌کند.
      - GetIoTAuthHistory(iotID): تاریخچه احراز هویت را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C IoTChannel -n AuthenticateIoT -c '{"function":"AuthenticateIoT","Args":["iot1","token123"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C IoTChannel -n AuthenticateIoT -c '{"function":"QueryAuthIoT","Args":["iot1"]}'
      ```

 3. **ConnectUser**:

    - **وظیفه کلی**: ثبت اتصال کاربران به شبکه 6G.
    - **ساختار داده**: Connection {UserID: string, AntennaID: string, Timestamp: string}
    - **توابع**:
      - ConnectUser(userID, antennaID): اتصال کاربر را ثبت می‌کند.
      - QueryConnection(userID): جزئیات اتصال را برمی‌گرداند.
      - UpdateConnection(userID, newAntennaID): اتصال را به‌روزرسانی می‌کند.
      - DisconnectUser(userID): اتصال کاربر را قطع می‌کند.
      - GetConnectionHistory(userID): تاریخچه اتصال را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C ConnectivityChannel -n ConnectUser -c '{"function":"ConnectUser","Args":["user1","Antenna1"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C ConnectivityChannel -n ConnectUser -c '{"function":"QueryConnection","Args":["user1"]}'
      ```

 4. **ConnectIoT**:

    - **وظیفه کلی**: ثبت اتصال دستگاه‌های IoT به شبکه.
    - **ساختار داده**: ConnectionIoT {IoTID: string, AntennaID: string, Timestamp: string}
    - **توابع**:
      - ConnectIoT(iotID, antennaID): اتصال دستگاه IoT را ثبت می‌کند.
      - QueryConnectionIoT(iotID): جزئیات اتصال را برمی‌گرداند.
      - UpdateIoTConnection(iotID, newAntennaID): اتصال را به‌روزرسانی می‌کند.
      - DisconnectIoT(iotID): اتصال دستگاه IoT را قطع می‌کند.
      - GetIoTConnectionHistory(iotID): تاریخچه اتصال را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C IoTChannel -n ConnectIoT -c '{"function":"ConnectIoT","Args":["iot1","Antenna1"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C IoTChannel -n ConnectIoT -c '{"function":"QueryConnectionIoT","Args":["iot1"]}'
      ```

 5. **RegisterUser**:

    - **وظیفه کلی**: ثبت‌نام کاربران در شبکه 6G.
    - **ساختار داده**: Registration {UserID: string, Timestamp: string}
    - **توابع**:
      - RegisterUser(userID): کاربر را ثبت می‌کند.
      - QueryUser(userID): وضعیت ثبت‌نام را برمی‌گرداند.
      - UpdateUserRegistration(userID): اطلاعات ثبت‌نام را به‌روزرسانی می‌کند.
      - DeregisterUser(userID): ثبت‌نام کاربر را لغو می‌کند.
      - GetRegistrationHistory(userID): تاریخچه ثبت‌نام را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C SecurityChannel -n RegisterUser -c '{"function":"RegisterUser","Args":["user1"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C SecurityChannel -n RegisterUser -c '{"function":"QueryUser","Args":["user1"]}'
      ```

 6. **RegisterIoT**:

    - **وظیفه کلی**: ثبت‌نام دستگاه‌های IoT در شبکه.
    - **ساختار داده**: RegistrationIoT {IoTID: string, Timestamp: string}
    - **توابع**:
      - RegisterIoT(iotID): دستگاه IoT را ثبت می‌کند.
      - QueryIoT(iotID): وضعیت ثبت‌نام را برمی‌گرداند.
      - UpdateIoTRegistration(iotID): اطلاعات ثبت‌نام را به‌روزرسانی می‌کند.
      - DeregisterIoT(iotID): ثبت‌نام دستگاه را لغو می‌کند.
      - GetIoTRegistrationHistory(iotID): تاریخچه ثبت‌نام را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C IoTChannel -n RegisterIoT -c '{"function":"RegisterIoT","Args":["iot1"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C IoTChannel -n RegisterIoT -c '{"function":"QueryIoT","Args":["iot1"]}'
      ```

 7. **RevokeUser**:

    - **وظیفه کلی**: لغو دسترسی کاربران از شبکه.
    - **ساختار داده**: Revocation {UserID: string, Timestamp: string}
    - **توابع**:
      - RevokeUser(userID): دسترسی کاربر را لغو می‌کند.
      - QueryRevokeUser(userID): وضعیت لغو را برمی‌گرداند.
      - ReinstateUser(userID): دسترسی کاربر را بازگردانی می‌کند.
      - LogRevocationHistory(userID): تاریخچه لغو را ثبت می‌کند.
      - GetRevocationHistory(userID): تاریخچه لغو را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C SecurityChannel -n RevokeUser -c '{"function":"RevokeUser","Args":["user1"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C SecurityChannel -n RevokeUser -c '{"function":"QueryRevokeUser","Args":["user1"]}'
      ```

 8. **RevokeIoT**:

    - **وظیفه کلی**: لغو دسترسی دستگاه‌های IoT از شبکه.
    - **ساختار داده**: RevocationIoT {IoTID: string, Timestamp: string}
    - **توابع**:
      - RevokeIoT(iotID): دسترسی دستگاه IoT را لغو می‌کند.
      - QueryRevokeIoT(iotID): وضعیت لغو را برمی‌گرداند.
      - ReinstateIoT(iotID): دسترسی دستگاه را بازگردانی می‌کند.
      - LogIoTRevocationHistory(iotID): تاریخچه لغو را ثبت می‌کند.
      - GetIoTRevocationHistory(iotID): تاریخچه لغو را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C IoTChannel -n RevokeIoT -c '{"function":"RevokeIoT","Args":["iot1"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C IoTChannel -n RevokeIoT -c '{"function":"QueryRevokeIoT","Args":["iot1"]}'
      ```

 9. **AssignRole**:

    - **وظیفه کلی**: تخصیص نقش (مانند Admin، User) به کاربران یا دستگاه‌ها.
    - **ساختار داده**: Role {EntityID: string, Role: string, Timestamp: string}
    - **توابع**:
      - AssignRole(entityID, role): نقش را تخصیص می‌دهد.
      - QueryRole(entityID): اطلاعات نقش را برمی‌گرداند.
      - UpdateRole(entityID, newRole): نقش را به‌روزرسانی می‌کند.
      - RemoveRole(entityID): نقش را حذف می‌کند.
      - GetRoleHistory(entityID): تاریخچه نقش را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C GeneralOperationsChannel -n AssignRole -c '{"function":"AssignRole","Args":["user1","Admin"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C GeneralOperationsChannel -n AssignRole -c '{"function":"QueryRole","Args":["user1"]}'
      ```

10. **GrantAccess**:

    - **وظیفه کلی**: اعطای دسترسی به منابع شبکه برای کاربران یا دستگاه‌ها.
    - **ساختار داده**: Access {EntityID: string, ResourceID: string, Permission: string, Timestamp: string}
    - **توابع**:
      - GrantAccess(entityID, resourceID, permission): دسترسی به منبع را اعطا می‌کند.
      - QueryAccess(entityID): اطلاعات دسترسی را برمی‌گرداند.
      - RevokeAccess(entityID, resourceID): دسترسی را لغو می‌کند.
      - ValidateAccess(entityID, resourceID, permission): صحت دسترسی را بررسی می‌کند.
      - GetAccessHistory(entityID): تاریخچه دسترسی را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C PolicyChannel -n GrantAccess -c '{"function":"GrantAccess","Args":["user1","resource1","Read"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C PolicyChannel -n GrantAccess -c '{"function":"QueryAccess","Args":["user1"]}'
      ```

11. **LogIdentityAudit**:

    - **وظیفه کلی**: ثبت لاگ برای حسابرسی هویت کاربران یا دستگاه‌ها.
    - **ساختار داده**: Audit {EntityID: string, Action: string, Timestamp: string}
    - **توابع**:
      - LogIdentityAudit(entityID, action): اقدام را برای حسابرسی ثبت می‌کند.
      - QueryIdentityAudit(entityID): لاگ حسابرسی را برمی‌گرداند.
      - ClearIdentityAudit(entityID): لاگ‌های حسابرسی را پاک می‌کند.
      - GetAuditHistory(entityID): تاریخچه حسابرسی را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C AuditChannel -n LogIdentityAudit -c '{"function":"LogIdentityAudit","Args":["user1","Login"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C AuditChannel -n LogIdentityAudit -c '{"function":"QueryIdentityAudit","Args":["user1"]}'
      ```

12. **AllocateIoTBandwidth**:

    - **وظیفه کلی**: تخصیص پهنای باند به دستگاه‌های IoT.
    - **ساختار داده**: IoTBandwidth {IoTID: string, Amount: string, Timestamp: string}
    - **توابع**:
      - AllocateIoTBandwidth(iotID, amount): پهنای باند را تخصیص می‌دهد.
      - QueryIoTBandwidth(iotID): پهنای باند را برمی‌گرداند.
      - AdjustIoTBandwidth(iotID, newAmount): پهنای باند را تنظیم می‌کند.
      - ReleaseIoTBandwidth(iotID): تخصیص پهنای باند را آزاد می‌کند.
      - GetIoTBandwidthHistory(iotID): تاریخچه تخصیص را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C IoTChannel -n AllocateIoTBandwidth -c '{"function":"AllocateIoTBandwidth","Args":["iot1","100"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C IoTChannel -n AllocateIoTBandwidth -c '{"function":"QueryIoTBandwidth","Args":["iot1"]}'
      ```

13. **UpdateAntennaLoad**:

    - **وظیفه کلی**: نظارت و به‌روزرسانی بار آنتن‌ها در شبکه.
    - **ساختار داده**: Load {AntennaID: string, Load: string, Timestamp: string}
    - **توابع**:
      - UpdateAntennaLoad(antennaID, load): بار آنتن را به‌روزرسانی می‌کند.
      - QueryAntennaLoad(antennaID): اطلاعات بار آنتن را برمی‌گرداند.
      - ResetAntennaLoad(antennaID): بار آنتن را بازنشانی می‌کند.
      - GetAntennaLoadHistory(antennaID): تاریخچه بار آنتن را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C PerformanceChannel -n UpdateAntennaLoad -c '{"function":"UpdateAntennaLoad","Args":["Antenna1","High"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C PerformanceChannel -n UpdateAntennaLoad -c '{"function":"QueryAntennaLoad","Args":["Antenna1"]}'
      ```

14. **RequestResource**:

    - **وظیفه کلی**: درخواست منابع توسط کاربران.
    - **ساختار داده**: Request {UserID: string, ResourceID: string, Amount: string, Timestamp: string}
    - **توابع**:
      - RequestResource(userID, resourceID, amount): درخواست منبع را ثبت می‌کند.
      - QueryRequest(userID): جزئیات درخواست را برمی‌گرداند.
      - CancelRequest(userID, resourceID): درخواست را لغو می‌کند.
      - ValidateRequest(userID, resourceID, amount): صحت درخواست را بررسی می‌کند.
      - GetRequestHistory(userID): تاریخچه درخواست را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C ResourceChannel -n RequestResource -c '{"function":"RequestResource","Args":["user1","resource1","100"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C ResourceChannel -n RequestResource -c '{"function":"QueryRequest","Args":["user1"]}'
      ```

15. **ShareSpectrum**:

    - **وظیفه کلی**: اشتراک‌گذاری طیف فرکانسی بین آنتن‌ها.
    - **ساختار داده**: Spectrum {AntennaID: string, Amount: string, Timestamp: string}
    - **توابع**:
      - ShareSpectrum(antennaID, amount): طیف را تخصیص می‌دهد.
      - QuerySpectrum(antennaID): میزان طیف را برمی‌گرداند.
      - AdjustSpectrum(antennaID, newAmount): مقدار طیف را تنظیم می‌کند.
      - ReleaseSpectrum(antennaID): تخصیص طیف را آزاد می‌کند.
      - GetSpectrumHistory(antennaID): تاریخچه تخصیص را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C ResourceChannel -n ShareSpectrum -c '{"function":"ShareSpectrum","Args":["Antenna1","50"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C ResourceChannel -n ShareSpectrum -c '{"function":"QuerySpectrum","Args":["Antenna1"]}'
      ```

16. **AssignGeneralPriority**:

    - **وظیفه کلی**: تخصیص اولویت عمومی به کاربران یا دستگاه‌ها.
    - **ساختار داده**: Priority {EntityID: string, Priority: string, Timestamp: string}
    - **توابع**:
      - AssignGeneralPriority(entityID, priority): اولویت را تنظیم می‌کند.
      - QueryGeneralPriority(entityID): اطلاعات اولویت را برمی‌گرداند.
      - UpdateGeneralPriority(entityID, newPriority): اولویت را به‌روزرسانی می‌کند.
      - RevokeGeneralPriority(entityID): اولویت را لغو می‌کند.
      - GetGeneralPriorityHistory(entityID): تاریخچه اولویت را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C PolicyChannel -n AssignGeneralPriority -c '{"function":"AssignGeneralPriority","Args":["user1","Urgent"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C PolicyChannel -n AssignGeneralPriority -c '{"function":"QueryGeneralPriority","Args":["user1"]}'
      ```

17. **LogResourceAudit**:

    - **وظیفه کلی**: حسابرسی استفاده از منابع شبکه.
    - **ساختار داده**: Audit {ResourceID: string, Action: string, Timestamp: string}
    - **توابع**:
      - LogResourceAudit(resourceID, action): اقدام را برای حسابرسی ثبت می‌کند.
      - QueryResourceAudit(resourceID): لاگ حسابرسی را برمی‌گرداند.
      - ClearResourceAudit(resourceID): لاگ‌های حسابرسی را پاک می‌کند.
      - GetResourceAuditHistory(resourceID): تاریخچه حسابرسی را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C AuditChannel -n LogResourceAudit -c '{"function":"LogResourceAudit","Args":["resource1","Allocate"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C AuditChannel -n LogResourceAudit -c '{"function":"QueryResourceAudit","Args":["resource1"]}'
      ```

18. **BalanceLoad**:

    - **وظیفه کلی**: تعادل بار بین آنتن‌ها.
    - **ساختار داده**: Balance {AntennaID: string, Load: string, Timestamp: string}
    - **توابع**:
      - BalanceLoad(antennaID, load): بار آنتن را متعادل می‌کند.
      - QueryBalance(antennaID): اطلاعات تعادل بار را برمی‌گرداند.
      - ResetBalance(antennaID): تعادل بار را بازنشانی می‌کند.
      - GetBalanceHistory(antennaID): تاریخچه تعادل بار را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C PerformanceChannel -n BalanceLoad -c '{"function":"BalanceLoad","Args":["Antenna1","Balanced"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C PerformanceChannel -n BalanceLoad -c '{"function":"QueryBalance","Args":["Antenna1"]}'
      ```

19. **AllocateDynamic**:

    - **وظیفه کلی**: تخصیص پویای منابع به کاربران یا دستگاه‌ها.
    - **ساختار داده**: Allocation {EntityID: string, ResourceID: string, Amount: string, Timestamp: string}
    - **توابع**:
      - AllocateDynamic(entityID, resourceID, amount): منبع را به‌صورت پویا تخصیص می‌دهد.
      - QueryAllocation(entityID): اطلاعات تخصیص را برمی‌گرداند.
      - ReleaseDynamicAllocation(entityID, resourceID): تخصیص را آزاد می‌کند.
      - ValidateDynamicAllocation(entityID, resourceID, amount): صحت تخصیص را بررسی می‌کند.
      - GetAllocationHistory(entityID): تاریخچه تخصیص را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C ResourceChannel -n AllocateDynamic -c '{"function":"AllocateDynamic","Args":["user1","resource1","100"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C ResourceChannel -n AllocateDynamic -c '{"function":"QueryAllocation","Args":["user1"]}'
      ```

20. **UpdateAntennaStatus**:

    - **وظیفه کلی**: به‌روزرسانی وضعیت آنتن‌ها (فعال/غیرفعال).
    - **ساختار داده**: AntennaStatus {AntennaID: string, Status: string, Timestamp: string}
    - **توابع**:
      - UpdateAntennaStatus(antennaID, status): وضعیت آنتن را به‌روزرسانی می‌کند.
      - QueryAntennaStatus(antennaID): اطلاعات وضعیت آنتن را برمی‌گرداند.
      - ResetAntennaStatus(antennaID): وضعیت آنتن را بازنشانی می‌کند.
      - GetAntennaStatusHistory(antennaID): تاریخچه وضعیت آنتن را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C PerformanceChannel -n UpdateAntennaStatus -c '{"function":"UpdateAntennaStatus","Args":["Antenna1","Active"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C PerformanceChannel -n UpdateAntennaStatus -c '{"function":"QueryAntennaStatus","Args":["Antenna1"]}'
      ```

21. **UpdateIoTStatus**:

    - **وظیفه کلی**: به‌روزرسانی وضعیت دستگاه‌های IoT (فعال/غیرفعال).
    - **ساختار داده**: IoTStatus {IoTID: string, Status: string, Timestamp: string}
    - **توابع**:
      - UpdateIoTStatus(iotID, status): وضعیت دستگاه IoT را به‌روزرسانی می‌کند.
      - QueryIoTStatus(iotID): اطلاعات وضعیت را برمی‌گرداند.
      - ResetIoTStatus(iotID): وضعیت دستگاه را بازنشانی می‌کند.
      - GetIoTStatusHistory(iotID): تاریخچه وضعیت دستگاه را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C IoTChannel -n UpdateIoTStatus -c '{"function":"UpdateIoTStatus","Args":["iot1","Active"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C IoTChannel -n UpdateIoTStatus -c '{"function":"QueryIoTStatus","Args":["iot1"]}'
      ```

22. **LogNetworkPerformance**:

    - **وظیفه کلی**: ثبت معیارهای عملکرد شبکه (مانند TPS، تأخیر).
    - **ساختار داده**: Performance {Metric: string, Value: string, Timestamp: string}
    - **توابع**:
      - LogNetworkPerformance(metric, value): معیار عملکرد را ثبت می‌کند.
      - QueryNetworkPerformance(metric): اطلاعات معیار را برمی‌گرداند.
      - ClearNetworkPerformance(metric): معیارهای عملکرد را پاک می‌کند.
      - GetPerformanceHistory(metric): تاریخچه معیارهای عملکرد را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C PerformanceChannel -n LogNetworkPerformance -c '{"function":"LogNetworkPerformance","Args":["TPS","100"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C PerformanceChannel -n LogNetworkPerformance -c '{"function":"QueryNetworkPerformance","Args":["TPS"]}'
      ```

23. **LogUserActivity**:

    - **وظیفه کلی**: ثبت فعالیت‌های کاربران (مانند ورود، خروج).
    - **ساختار داده**: Activity {UserID: string, Action: string, Timestamp: string}
    - **توابع**:
      - LogUserActivity(userID, action): فعالیت کاربر را ثبت می‌کند.
      - QueryUserActivity(userID): اطلاعات فعالیت را برمی‌گرداند.
      - ClearUserActivity(userID): فعالیت‌های کاربر را پاک می‌کند.
      - GetUserActivityHistory(userID): تاریخچه فعالیت‌ها را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C AuditChannel -n LogUserActivity -c '{"function":"LogUserActivity","Args":["user1","Login"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C AuditChannel -n LogUserActivity -c '{"function":"QueryUserActivity","Args":["user1"]}'
      ```

24. **DetectAntennaFault**:

    - **وظیفه کلی**: تشخیص خطاهای آنتن‌ها (مانند قطعی سیگنال).
    - **ساختار داده**: Fault {AntennaID: string, Fault: string, Timestamp: string}
    - **توابع**:
      - DetectAntennaFault(antennaID, fault): خطای آنتن را ثبت می‌کند.
      - QueryAntennaFault(antennaID): جزئیات خطا را برمی‌گرداند.
      - ResolveAntennaFault(antennaID): خطا را رفع می‌کند.
      - GetAntennaFaultHistory(antennaID): تاریخچه خطاها را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C PerformanceChannel -n DetectAntennaFault -c '{"function":"DetectAntennaFault","Args":["Antenna1","SignalLoss"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C PerformanceChannel -n DetectAntennaFault -c '{"function":"QueryAntennaFault","Args":["Antenna1"]}'
      ```

25. **DetectIoTFault**:

    - **وظیفه کلی**: تشخیص خطاهای دستگاه‌های IoT (مانند خرابی منبع تغذیه).
    - **ساختار داده**: IoTFault {IoTID: string, Fault: string, Timestamp: string}
    - **توابع**:
      - DetectIoTFault(iotID, fault): خطای دستگاه IoT را ثبت می‌کند.
      - QueryIoTFault(iotID): جزئیات خطا را برمی‌گرداند.
      - ResolveIoTFault(iotID): خطا را رفع می‌کند.
      - GetIoTFaultHistory(iotID): تاریخچه خطاها را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C IoTChannel -n DetectIoTFault -c '{"function":"DetectIoTFault","Args":["iot1","PowerFailure"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C IoTChannel -n DetectIoTFault -c '{"function":"QueryIoTFault","Args":["iot1"]}'
      ```

26. **MonitorAntennaTraffic**:

    - **وظیفه کلی**: نظارت بر ترافیک شبکه در آنتن‌ها.
    - **ساختار داده**: Traffic {AntennaID: string, Traffic: string, Timestamp: string}
    - **توابع**:
      - MonitorAntennaTraffic(antennaID, traffic): ترافیک آنتن را ثبت می‌کند.
      - QueryAntennaTraffic(antennaID): اطلاعات ترافیک را برمی‌گرداند.
      - AdjustAntennaTraffic(antennaID, newTraffic): سطح ترافیک را تنظیم می‌کند.
      - GetAntennaTrafficHistory(antennaID): تاریخچه ترافیک را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C PerformanceChannel -n MonitorAntennaTraffic -c '{"function":"MonitorAntennaTraffic","Args":["Antenna1","High"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C PerformanceChannel -n MonitorAntennaTraffic -c '{"function":"QueryAntennaTraffic","Args":["Antenna1"]}'
      ```

27. **GenerateReport**:

    - **وظیفه کلی**: تولید گزارش‌های عملکرد شبکه.
    - **ساختار داده**: Report {ReportID: string, Content: string, Timestamp: string}
    - **توابع**:
      - GenerateReport(reportID, content): گزارش را ثبت می‌کند.
      - QueryReport(reportID): اطلاعات گزارش را برمی‌گرداند.
      - UpdateReport(reportID, newContent): گزارش را به‌روزرسانی می‌کند.
      - DeleteReport(reportID): گزارش را حذف می‌کند.
      - GetReportHistory(reportID): تاریخچه گزارش را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C GeneralOperationsChannel -n GenerateReport -c '{"function":"GenerateReport","Args":["report1","NetworkStatus"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C GeneralOperationsChannel -n GenerateReport -c '{"function":"QueryReport","Args":["report1"]}'
      ```

28. **TrackLatency**:

    - **وظیفه کلی**: ردیابی تأخیر شبکه در آنتن‌ها.
    - **ساختار داده**: Latency {AntennaID: string, Latency: string, Timestamp: string}
    - **توابع**:
      - TrackLatency(antennaID, latency): تأخیر شبکه را ثبت می‌کند.
      - QueryLatency(antennaID): اطلاعات تأخیر را برمی‌گرداند.
      - UpdateLatency(antennaID, newLatency): تأخیر را به‌روزرسانی می‌کند.
      - GetLatencyHistory(antennaID): تاریخچه تأخیر را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C PerformanceChannel -n TrackLatency -c '{"function":"TrackLatency","Args":["Antenna1","10ms"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C PerformanceChannel -n TrackLatency -c '{"function":"QueryLatency","Args":["Antenna1"]}'
      ```

29. **MonitorEnergy**:

    - **وظیفه کلی**: نظارت بر مصرف انرژی آنتن‌ها.
    - **ساختار داده**: Energy {AntennaID: string, Energy: string, Timestamp: string}
    - **توابع**:
      - MonitorEnergy(antennaID, energy): مصرف انرژی را ثبت می‌کند.
      - QueryEnergy(antennaID): اطلاعات مصرف انرژی را برمی‌گرداند.
      - OptimizeEnergy(antennaID, targetEnergy): مصرف انرژی را بهینه می‌کند.
      - GetEnergyHistory(antennaID): تاریخچه مصرف انرژی را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C PerformanceChannel -n MonitorEnergy -c '{"function":"MonitorEnergy","Args":["Antenna1","50W"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C PerformanceChannel -n MonitorEnergy -c '{"function":"QueryEnergy","Args":["Antenna1"]}'
      ```

30. **PerformRoaming**:

    - **وظیفه کلی**: مدیریت رومینگ کاربران یا دستگاه‌ها بین آنتن‌ها.
    - **ساختار داده**: Roaming {EntityID: string, FromAntenna: string, ToAntenna: string, Timestamp: string}
    - **توابع**:
      - PerformRoaming(entityID, fromAntenna, toAntenna): رومینگ را ثبت می‌کند.
      - QueryRoaming(entityID): جزئیات رومینگ را برمی‌گرداند.
      - ValidateRoaming(entityID, fromAntenna, toAntenna): صحت رومینگ را بررسی می‌کند.
      - LogRoamingHistory(entityID): تاریخچه رومینگ را ثبت می‌کند.
      - GetRoamingHistory(entityID): تاریخچه رومینگ را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C ConnectivityChannel -n PerformRoaming -c '{"function":"PerformRoaming","Args":["user1","Antenna1","Antenna2"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C ConnectivityChannel -n PerformRoaming -c '{"function":"QueryRoaming","Args":["user1"]}'
      ```

31. **TrackSession**:

    - **وظیفه کلی**: ردیابی جلسات کاربران در شبکه.
    - **ساختار داده**: Session {UserID: string, SessionID: string, Timestamp: string}
    - **توابع**:
      - TrackSession(userID, sessionID): جلسه کاربر را ثبت می‌کند.
      - QuerySession(userID): جزئیات جلسه را برمی‌گرداند.
      - EndSession(userID, sessionID): جلسه را پایان می‌دهد.
      - GetSessionHistory(userID): تاریخچه جلسات را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C SessionChannel -n TrackSession -c '{"function":"TrackSession","Args":["user1","session1"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C SessionChannel -n TrackSession -c '{"function":"QuerySession","Args":["user1"]}'
      ```

32. **TrackIoTSession**:

    - **وظیفه کلی**: ردیابی جلسات دستگاه‌های IoT.
    - **ساختار داده**: IoTSession {IoTID: string, SessionID: string, Timestamp: string}
    - **توابع**:
      - TrackIoTSession(iotID, sessionID): جلسه دستگاه IoT را ثبت می‌کند.
      - QueryIoTSession(iotID): جزئیات جلسه را برمی‌گرداند.
      - EndIoTSession(iotID, sessionID): جلسه را پایان می‌دهد.
      - GetIoTSessionHistory(iotID): تاریخچه جلسات را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C IoTChannel -n TrackIoTSession -c '{"function":"TrackIoTSession","Args":["iot1","session1"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C IoTChannel -n TrackIoTSession -c '{"function":"QueryIoTSession","Args":["iot1"]}'
      ```

33. **DisconnectEntity**:

    - **وظیفه کلی**: قطع اتصال کاربران یا دستگاه‌ها از شبکه.
    - **ساختار داده**: Disconnect {EntityID: string, AntennaID: string, Timestamp: string}
    - **توابع**:
      - DisconnectEntity(entityID, antennaID): قطع اتصال را ثبت می‌کند.
      - QueryDisconnect(entityID): اطلاعات قطع اتصال را برمی‌گرداند.
      - ReconnectEntity(entityID, antennaID): اتصال را بازگردانی می‌کند.
      - GetDisconnectHistory(entityID): تاریخچه قطع اتصال‌ها را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C ConnectivityChannel -n DisconnectEntity -c '{"function":"DisconnectEntity","Args":["user1","Antenna1"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C ConnectivityChannel -n DisconnectEntity -c '{"function":"QueryDisconnect","Args":["user1"]}'
      ```

34. **GenerateBill**:

    - **وظیفه کلی**: صدور صورت‌حساب برای کاربران.
    - **ساختار داده**: Billing {UserID: string, Amount: string, Timestamp: string}
    - **توابع**:
      - GenerateBill(userID, amount): صورت‌حساب را ثبت می‌کند.
      - QueryBill(userID): اطلاعات صورت‌حساب را برمی‌گرداند.
      - UpdateBill(userID, newAmount): صورت‌حساب را به‌روزرسانی می‌کند.
      - CancelBill(userID): صورت‌حساب را لغو می‌کند.
      - GetBillHistory(userID): تاریخچه صورت‌حساب را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C BillingChannel -n GenerateBill -c '{"function":"GenerateBill","Args":["user1","100"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C BillingChannel -n GenerateBill -c '{"function":"QueryBill","Args":["user1"]}'
      ```

35. **LogTransaction**:

    - **وظیفه کلی**: ثبت لاگ تراکنش‌های شبکه.
    - **ساختار داده**: Transaction {TxID: string, Details: string, Timestamp: string}
    - **توابع**:
      - LogTransaction(txID, details): تراکنش را ثبت می‌کند.
      - QueryTransaction(txID): جزئیات تراکنش را برمی‌گرداند.
      - ClearTransaction(txID): لاگ تراکنش را پاک می‌کند.
      - GetTransactionHistory(txID): تاریخچه تراکنش‌ها را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C AuditChannel -n LogTransaction -c '{"function":"LogTransaction","Args":["tx1","Details"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C AuditChannel -n LogTransaction -c '{"function":"QueryTransaction","Args":["tx1"]}'
      ```

36. **LogConnectionAudit**:

    - **وظیفه کلی**: حسابرسی اتصالات شبکه برای کاربران یا دستگاه‌ها.
    - **ساختار داده**: ConnectionAudit {EntityID: string, Action: string, Timestamp: string}
    - **توابع**:
      - LogConnectionAudit(entityID, action): اقدام اتصال را ثبت می‌کند.
      - QueryConnectionAudit(entityID): لاگ حسابرسی اتصال را برمی‌گرداند.
      - ClearConnectionAudit(entityID): لاگ‌های حسابرسی را پاک می‌کند.
      - GetConnectionAuditHistory(entityID): تاریخچه حسابرسی را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C AuditChannel -n LogConnectionAudit -c '{"function":"LogConnectionAudit","Args":["user1","Connect"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C AuditChannel -n LogConnectionAudit -c '{"function":"QueryConnectionAudit","Args":["user1"]}'
      ```

37. **EncryptData**:

    - **وظیفه کلی**: رمزنگاری داده‌های کاربران برای امنیت.
    - **ساختار داده**: Encryption {UserID: string, Data: string, Timestamp: string}
    - **توابع**:
      - EncryptData(userID, data): داده کاربر را رمزنگاری و ثبت می‌کند.
      - QueryEncryptedData(userID): داده رمزنگاری‌شده را برمی‌گرداند.
      - UpdateEncryptedData(userID, newData): داده رمزنگاری‌شده را به‌روزرسانی می‌کند.
      - DeleteEncryptedData(userID): داده رمزنگاری‌شده را حذف می‌کند.
      - GetEncryptionHistory(userID): تاریخچه رمزنگاری را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C SecurityChannel -n EncryptData -c '{"function":"EncryptData","Args":["user1","SensitiveData"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C SecurityChannel -n EncryptData -c '{"function":"QueryEncryptedData","Args":["user1"]}'
      ```

38. **EncryptIoTData**:

    - **وظیفه کلی**: رمزنگاری داده‌های دستگاه‌های IoT.
    - **ساختار داده**: IoTEncryption {IoTID: string, Data: string, Timestamp: string}
    - **توابع**:
      - EncryptIoTData(iotID, data): داده دستگاه IoT را رمزنگاری و ثبت می‌کند.
      - QueryEncryptedIoTData(iotID): داده رمزنگاری‌شده را برمی‌گرداند.
      - UpdateEncryptedIoTData(iotID, newData): داده رمزنگاری‌شده را به‌روزرسانی می‌کند.
      - DeleteEncryptedIoTData(iotID): داده رمزنگاری‌شده را حذف می‌کند.
      - GetIoTEncryptionHistory(iotID): تاریخچه رمزنگاری را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C IoTChannel -n EncryptIoTData -c '{"function":"EncryptIoTData","Args":["iot1","SensorData"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C IoTChannel -n EncryptIoTData -c '{"function":"QueryEncryptedIoTData","Args":["iot1"]}'
      ```

39. **LogAccess**:

    - **وظیفه کلی**: ثبت لاگ دسترسی به منابع شبکه.
    - **ساختار داده**: AccessLog {EntityID: string, ResourceID: string, Timestamp: string}
    - **توابع**:
      - LogAccess(entityID, resourceID): دسترسی به منبع را ثبت می‌کند.
      - QueryAccessLog(entityID): لاگ دسترسی را برمی‌گرداند.
      - ClearAccessLog(entityID): لاگ‌های دسترسی را پاک می‌کند.
      - GetAccessLogHistory(entityID): تاریخچه دسترسی را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C AuditChannel -n LogAccess -c '{"function":"LogAccess","Args":["user1","resource1"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C AuditChannel -n LogAccess -c '{"function":"QueryAccessLog","Args":["user1"]}'
      ```

40. **DetectIntrusion**:

    - **وظیفه کلی**: تشخیص نفوذ و فعالیت‌های مشکوک در شبکه.
    - **ساختار داده**: Intrusion {EntityID: string, Details: string, Timestamp: string}
    - **توابع**:
      - DetectIntrusion(entityID, details): نفوذ یا فعالیت مشکوک را ثبت می‌کند.
      - QueryIntrusion(entityID): جزئیات نفوذ را برمی‌گرداند.
      - ResolveIntrusion(entityID): مشکل نفوذ را رفع می‌کند.
      - GetIntrusionHistory(entityID): تاریخچه نفوذها را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C SecurityChannel -n DetectIntrusion -c '{"function":"DetectIntrusion","Args":["user1","SuspiciousActivity"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C SecurityChannel -n DetectIntrusion -c '{"function":"QueryIntrusion","Args":["user1"]}'
      ```

41. **ManageKey**:

    - **وظیفه کلی**: مدیریت کلیدهای رمزنگاری برای کاربران یا دستگاه‌ها.
    - **ساختار داده**: Key {EntityID: string, Key: string, Timestamp: string}
    - **توابع**:
      - ManageKey(entityID, key): کلید رمزنگاری را ثبت می‌کند.
      - QueryKey(entityID): اطلاعات کلید را برمی‌گرداند.
      - UpdateKey(entityID, newKey): کلید را به‌روزرسانی می‌کند.
      - DeleteKey(entityID): کلید را حذف می‌کند.
      - GetKeyHistory(entityID): تاریخچه کلید را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C SecurityChannel -n ManageKey -c '{"function":"ManageKey","Args":["user1","key123"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C SecurityChannel -n ManageKey -c '{"function":"QueryKey","Args":["user1"]}'
      ```

42. **SetPolicy**:

    - **وظیفه کلی**: تنظیم سیاست‌های حریم خصوصی برای کاربران یا دستگاه‌ها.
    - **ساختار داده**: Policy {EntityID: string, Policy: string, Timestamp: string}
    - **توابع**:
      - SetPolicy(entityID, policy): سیاست حریم خصوصی را ثبت می‌کند.
      - QueryPolicy(entityID): اطلاعات سیاست را برمی‌گرداند.
      - UpdatePolicy(entityID, newPolicy): سیاست را به‌روزرسانی می‌کند.
      - RemovePolicy(entityID): سیاست را حذف می‌کند.
      - GetPolicyHistory(entityID): تاریخچه سیاست را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C PolicyChannel -n SetPolicy -c '{"function":"SetPolicy","Args":["user1","Restricted"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C PolicyChannel -n SetPolicy -c '{"function":"QueryPolicy","Args":["user1"]}'
      ```

43. **CreateSecureChannel**:

    - **وظیفه کلی**: ایجاد کانال‌های امن برای ارتباطات.
    - **ساختار داده**: SecureChannel {EntityID: string, ChannelID: string, Timestamp: string}
    - **توابع**:
      - CreateSecureChannel(entityID, channelID): کانال امن را ثبت می‌کند.
      - QuerySecureChannel(entityID): اطلاعات کانال را برمی‌گرداند.
      - CloseSecureChannel(entityID, channelID): کانال امن را می‌بندد.
      - GetSecureChannelHistory(entityID): تاریخچه کانال‌های امن را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C SecurityChannel -n CreateSecureChannel -c '{"function":"CreateSecureChannel","Args":["user1","channel1"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C SecurityChannel -n CreateSecureChannel -c '{"function":"QuerySecureChannel","Args":["user1"]}'
      ```

44. **LogSecurityAudit**:

    - **وظیفه کلی**: حسابرسی امنیتی برای اقدامات شبکه.
    - **ساختار داده**: SecurityAudit {EntityID: string, Action: string, Timestamp: string}
    - **توابع**:
      - LogSecurityAudit(entityID, action): اقدام امنیتی را ثبت می‌کند.
      - QuerySecurityAudit(entityID): لاگ حسابرسی امنیتی را برمی‌گرداند.
      - ClearSecurityAudit(entityID): لاگ‌های حسابرسی را پاک می‌کند.
      - GetSecurityAuditHistory(entityID): تاریخچه حسابرسی را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C AuditChannel -n LogSecurityAudit -c '{"function":"LogSecurityAudit","Args":["user1","SecurityCheck"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C AuditChannel -n LogSecurityAudit -c '{"function":"QuerySecurityAudit","Args":["user1"]}'
      ```

45. **AuthenticateAntenna**:

    - **وظیفه کلی**: احراز هویت آنتن‌ها برای امنیت شبکه.
    - **ساختار داده**: AntennaAuth {AntennaID: string, Token: string, Timestamp: string}
    - **توابع**:
      - AuthenticateAntenna(antennaID, token): توکن آنتن را ثبت می‌کند.
      - QueryAntennaAuth(antennaID): وضعیت احراز هویت را برمی‌گرداند.
      - RevokeAntennaAuth(antennaID): احراز هویت را لغو می‌کند.
      - ValidateAntennaToken(antennaID, token): صحت توکن را بررسی می‌کند.
      - GetAntennaAuthHistory(antennaID): تاریخچه احراز هویت را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C SecurityChannel -n AuthenticateAntenna -c '{"function":"AuthenticateAntenna","Args":["Antenna1","token123"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C SecurityChannel -n AuthenticateAntenna -c '{"function":"QueryAntennaAuth","Args":["Antenna1"]}'
      ```

46. **MonitorNetworkCongestion**:

    - **وظیفه کلی**: نظارت بر ازدحام شبکه.
    - **ساختار داده**: Congestion {AntennaID: string, CongestionLevel: string, Timestamp: string}
    - **توابع**:
      - MonitorNetworkCongestion(antennaID, congestionLevel): ازدحام شبکه را ثبت می‌کند.
      - QueryNetworkCongestion(antennaID): اطلاعات ازدحام را برمی‌گرداند.
      - MitigateNetworkCongestion(antennaID): ازدحام را کاهش می‌دهد.
      - GetCongestionHistory(antennaID): تاریخچه ازدحام را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C PerformanceChannel -n MonitorNetworkCongestion -c '{"function":"MonitorNetworkCongestion","Args":["Antenna1","High"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C PerformanceChannel -n MonitorNetworkCongestion -c '{"function":"QueryNetworkCongestion","Args":["Antenna1"]}'
      ```

47. **AllocateNetworkResource**:

    - **وظیفه کلی**: تخصیص منابع عمومی شبکه.
    - **ساختار داده**: NetworkResource {EntityID: string, ResourceID: string, Amount: string, Timestamp: string}
    - **توابع**:
      - AllocateNetworkResource(entityID, resourceID, amount): منبع را تخصیص می‌دهد.
      - QueryNetworkResource(entityID): اطلاعات تخصیص را برمی‌گرداند.
      - ReleaseNetworkResource(entityID, resourceID): تخصیص را آزاد می‌کند.
      - ValidateNetworkResource(entityID, resourceID, amount): صحت تخصیص را بررسی می‌کند.
      - GetNetworkResourceHistory(entityID): تاریخچه تخصیص را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C ResourceChannel -n AllocateNetworkResource -c '{"function":"AllocateNetworkResource","Args":["user1","resource1","100"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C ResourceChannel -n AllocateNetworkResource -c '{"function":"QueryNetworkResource","Args":["user1"]}'
      ```

48. **MonitorNetworkHealth**:

    - **وظیفه کلی**: نظارت بر سلامت کلی شبکه.
    - **ساختار داده**: NetworkHealth {Metric: string, HealthStatus: string, Timestamp: string}
    - **توابع**:
      - MonitorNetworkHealth(metric, healthStatus): سلامت شبکه را ثبت می‌کند.
      - QueryNetworkHealth(metric): اطلاعات سلامت را برمی‌گرداند.
      - UpdateNetworkHealth(metric, newHealthStatus): سلامت شبکه را به‌روزرسانی می‌کند.
      - GetNetworkHealthHistory(metric): تاریخچه سلامت را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C PerformanceChannel -n MonitorNetworkHealth -c '{"function":"MonitorNetworkHealth","Args":["Network","Stable"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C PerformanceChannel -n MonitorNetworkHealth -c '{"function":"QueryNetworkHealth","Args":["Network"]}'
      ```

49. **ManageNetworkPolicy**:

    - **وظیفه کلی**: مدیریت سیاست‌های شبکه برای امنیت و عملکرد.
    - **ساختار داده**: NetworkPolicy {EntityID: string, Policy: string, Timestamp: string}
    - **توابع**:
      - ManageNetworkPolicy(entityID, policy): سیاست شبکه را ثبت می‌کند.
      - QueryNetworkPolicy(entityID): اطلاعات سیاست را برمی‌گرداند.
      - UpdateNetworkPolicy(entityID, newPolicy): سیاست را به‌روزرسانی می‌کند.
      - RemoveNetworkPolicy(entityID): سیاست را حذف می‌کند.
      - GetNetworkPolicyHistory(entityID): تاریخچه سیاست را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C PolicyChannel -n ManageNetworkPolicy -c '{"function":"ManageNetworkPolicy","Args":["user1","Restricted"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C PolicyChannel -n ManageNetworkPolicy -c '{"function":"QueryNetworkPolicy","Args":["user1"]}'
      ```

50. **LogNetworkAudit**:

    - **وظیفه کلی**: حسابرسی کلی شبکه برای ردیابی اقدامات.
    - **ساختار داده**: NetworkAudit {EntityID: string, Action: string, Timestamp: string}
    - **توابع**:
      - LogNetworkAudit(entityID, action): اقدام شبکه را ثبت می‌کند.
      - QueryNetworkAudit(entityID): لاگ حسابرسی را برمی‌گرداند.
      - ClearNetworkAudit(entityID): لاگ‌های حسابرسی را پاک می‌کند.
      - GetNetworkAuditHistory(entityID): تاریخچه حسابرسی را برمی‌گرداند.
    - **مثال دستورات**:

      ```bash
      peer chaincode invoke -C AuditChannel -n LogNetworkAudit -c '{"function":"LogNetworkAudit","Args":["user1","NetworkCheck"]}' --tls --cafile /crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
      peer chaincode query -C AuditChannel -n LogNetworkAudit -c '{"function":"QueryNetworkAudit","Args":["user1"]}'
      ```
