object DataModule2: TDataModule2
  OldCreateOrder = False
  Height = 299
  Width = 460
  object ADOConnection1: TADOConnection
    CommandTimeout = 10
    ConnectionString = 
      'Provider=SQLOLEDB.1;Password=12345678;Persist Security Info=True' +
      ';User ID=sa;Initial Catalog=scale_turntable;Data Source=krr-ws03' +
      '302;Use Procedure for Prepare=1;Auto Translate=True;Packet Size=' +
      '4096;Workstation ID=KRR-WS08022;Use Encryption for Data=False;Ta' +
      'g with column collation when possible=False'
    LoginPrompt = False
    Provider = 'SQLOLEDB.1'
    Left = 40
    Top = 8
  end
  object ADOQuery1: TADOQuery
    Connection = ADOConnection1
    CursorType = ctStatic
    Parameters = <>
    SQL.Strings = (
      'SELECT *  FROM  scale_turntable.dbo.mass')
    Left = 200
    Top = 8
  end
  object DataSource1: TDataSource
    DataSet = ADOQuery1
    Left = 128
    Top = 8
  end
  object query_count: TADOQuery
    Connection = ADOConnection1
    Parameters = <>
    Left = 264
    Top = 8
  end
  object ib_datasource: TDataSource
    DataSet = ib_query_view
    Left = 120
    Top = 224
  end
  object ib_timer: TTimer
    Enabled = False
    OnTimer = ib_timerTimer
    Left = 16
    Top = 120
  end
  object ib_connection: TADOConnection
    ConnectionString = 
      'Provider=MSDASQL.1;Password=masterkey;Persist Security Info=True' +
      ';User ID=sysdba;Data Source=firebird'
    LoginPrompt = False
    Provider = 'MSDASQL.1'
    Left = 32
    Top = 224
  end
  object ib_query: TADOQuery
    Connection = ib_connection
    Parameters = <>
    Left = 192
    Top = 224
  end
  object ib_query_count: TADOQuery
    Connection = ib_connection
    Parameters = <>
    Left = 264
    Top = 224
  end
  object ib_query_view: TADOQuery
    Connection = ib_connection
    Parameters = <>
    Left = 344
    Top = 224
  end
  object query_reports: TADOQuery
    Connection = ADOConnection1
    CursorType = ctStatic
    Parameters = <>
    SQL.Strings = (
      'SELECT *  FROM  scale_turntable.dbo.mass')
    Left = 336
    Top = 8
  end
  object query_s_g_c: TADOQuery
    Connection = ADOConnection1
    Parameters = <>
    Left = 408
    Top = 8
  end
end
