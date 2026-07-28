# قراردادهای مکانی بازنویسی‌شده — امضاهای جدید

| قرارداد | کانال | تابع | پارامترها | قبلاً قفل |
|---|---|---|---|---|
| LocationBasedAntennaConfig | managementchannel | `SetAntennaConfig` | antennaID, config, x, y, seed | — |
| LocationBasedAssignment | datachannel | `AssignAntenna` | entityID, x, y, seed | 🔴 بله |
| LocationBasedBandwidth | datachannel | `AssignBandwidth` | entityID, bandwidth, x, y, seed | 🔴 بله |
| LocationBasedChannelAllocation | managementchannel | `AllocateChannel` | entityID, channelID, x, y, seed | — |
| LocationBasedCongestion | trafficchannel | `RecordCongestion` | entityID, congestion, x, y, seed | — |
| LocationBasedConnection | connectivitychannel | `ConnectEntity` | entityID, x, y, seed | 🔴 بله |
| LocationBasedCoverage | analyticschannel | `RecordCoverage` | entityID, coverage, x, y, seed | — |
| LocationBasedDynamicRouting | optimizationchannel | `SetDynamicRoute` | entityID, route, x, y, seed | — |
| LocationBasedEnergy | analyticschannel | `RecordEnergy` | entityID, energy, x, y, seed | — |
| LocationBasedFault | faultchannel | `ReportFault` | entityID, faultType, x, y, seed | — |
| LocationBasedInterference | integrationchannel | `RecordInterference` | entityID, interferenceLevel, x, y, seed | — |
| LocationBasedIoTAuthentication | authchannel | `AuthenticateIoT` | deviceID, token, x, y, seed | — |
| LocationBasedIoTBandwidth | iotchannel | `AllocateIoTBandwidth` | deviceID, bandwidth, x, y, seed | 🔴 بله |
| LocationBasedIoTConnection | iotchannel | `ConnectIoT` | deviceID, x, y, seed | 🔴 بله |
| LocationBasedIoTFault | iotchannel, faultchannel | `ReportIoTFault` | deviceID, faultType, x, y, seed | — |
| LocationBasedIoTRegistration | accesschannel | `RegisterIoT` | deviceID, status, x, y, seed | — |
| LocationBasedIoTResource | resourcechannel | `AllocateIoTResource` | deviceID, resourceID, amount, x, y, seed | — |
| LocationBasedIoTRevocation | accesschannel | `RevokeIoT` | deviceID, status, x, y, seed | — |
| LocationBasedIoTSession | iotchannel, sessionchannel | `StartIoTSession` | deviceID, sessionID, status, x, y, seed | — |
| LocationBasedIoTStatus | iotchannel | `UpdateIoTStatus` | deviceID, status, x, y, seed | — |
| LocationBasedLatency | performancechannel | `RecordLatency` | entityID, latency, x, y, seed | — |
| LocationBasedNetworkHealth | networkchannel | `RecordNetworkHealth` | entityID, healthStatus, x, y, seed | — |
| LocationBasedNetworkLoad | networkchannel | `RecordNetworkLoad` | entityID, load, x, y, seed | — |
| LocationBasedPowerManagement | managementchannel | `SetPowerLevel` | entityID, powerLevel, x, y, seed | — |
| LocationBasedPriority | compliancechannel | `AssignPriority` | entityID, priority, x, y, seed | — |
| LocationBasedQoS | analyticschannel | `AssignQoS` | entityID, qosLevel, x, y, seed | 🔴 بله |
| LocationBasedResourceAllocation | resourcechannel | `AllocateResource` | entityID, resourceID, amount, x, y, seed | — |
| LocationBasedRoaming | connectivitychannel | `PerformRoaming` | entityID, x, y, seed | 🔴 بله |
| LocationBasedSessionManagement | sessionchannel | `ManageSession` | entityID, sessionID, status, x, y, seed | — |
| LocationBasedSignalQuality | datachannel | `RecordSignalQuality` | entityID, signalQuality, x, y, seed | — |
| LocationBasedSignalStrength | datachannel, integrationchannel | `RecordSignalStrength` | entityID, signal, x, y, seed | — |
| LocationBasedStatus | monitoringchannel | `UpdateStatus` | entityID, status, x, y, seed | — |
| LocationBasedTraffic | trafficchannel | `RecordTraffic` | entityID, traffic, x, y, seed | — |
| LocationBasedUserActivity | integrationchannel | `RecordUserActivity` | userID, activity, x, y, seed | — |
