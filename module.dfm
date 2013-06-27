object Module1: TModule1
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  Height = 234
  Width = 319
  object ApdDataPacket1: TApdDataPacket
    Enabled = True
    EndCond = [ecString]
    StartString = '#2'
    EndString = '#3'
    ComPort = ApdComPort1
    PacketSize = 0
    OnStringPacket = ApdDataPacket1StringPacket
    Left = 248
    Top = 11
  end
  object ApdComPort1: TApdComPort
    ComNumber = 1
    Baud = 9600
    Parity = pEven
    TraceName = 'APRO.TRC'
    LogName = 'APRO.LOG'
    LogHex = False
    OnPortClose = ApdComPort1PortClose
    OnPortOpen = ApdComPort1PortOpen
    Left = 248
    Top = 75
  end
  object pFIBDatabase1: TpFIBDatabase
    AutoReconnect = True
    SQLDialect = 1
    Timeout = 0
    WaitForRestoreConnect = 0
    Left = 32
    Top = 8
  end
  object pFibErrorHandler1: TpFibErrorHandler
    OnFIBErrorEvent = pFibErrorHandler1FIBErrorEvent
    Left = 32
    Top = 120
  end
  object pFIBDataSet1: TpFIBDataSet
    Transaction = pFIBTransaction1
    Database = pFIBDatabase1
    Left = 128
    Top = 64
  end
  object pFIBQuery1: TpFIBQuery
    Transaction = pFIBTransaction1
    Database = pFIBDatabase1
    Left = 32
    Top = 64
  end
  object pFIBTransaction1: TpFIBTransaction
    DefaultDatabase = pFIBDatabase1
    TimeoutAction = TACommit
    TRParams.Strings = (
      'write'
      'isc_tpb_nowait'
      'read_committed'
      'rec_version')
    TPBMode = tpbDefault
    Left = 128
    Top = 8
  end
  object OraSession1: TOraSession
    LoginPrompt = False
    Left = 32
    Top = 176
  end
  object OraQuery1: TOraQuery
    Left = 128
    Top = 176
  end
  object FIB_DataSource: TDataSource
    DataSet = pFIBDataSet1
    Left = 128
    Top = 120
  end
end
