object Form1: TForm1
  Left = 177
  Top = 0
  BorderStyle = bsSingle
  Caption = 'Form1'
  ClientHeight = 705
  ClientWidth = 994
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  KeyPreview = True
  OldCreateOrder = False
  Position = poDesktopCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  OnShow = InitForm
  PixelsPerInch = 96
  TextHeight = 13
  object Label7: TLabel
    AlignWithMargins = True
    Left = 471
    Top = 152
    Width = 233
    Height = 28
    Alignment = taCenter
    AutoSize = False
    Caption = 'Label7'
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = 16685313
    Font.Height = -24
    Font.Name = 'Arial Narrow'
    Font.Style = [fsBold]
    ParentFont = False
    Visible = False
  end
  object Label10: TLabel
    Left = 471
    Top = 198
    Width = 233
    Height = 28
    Alignment = taCenter
    AutoSize = False
    Caption = 'last  '#1074#1079#1074#1077#1096#1077#1085#1085#1072#1103
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = 16685313
    Font.Height = -24
    Font.Name = 'Arial Narrow'
    Font.Style = [fsBold]
    ParentFont = False
    Visible = False
  end
  object Label6: TLabel
    Left = 8
    Top = 607
    Width = 27
    Height = 20
    Caption = 'help'
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial Narrow'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Label5: TLabel
    AlignWithMargins = True
    Left = 8
    Top = 121
    Width = 177
    Height = 25
    AutoSize = False
    BiDiMode = bdLeftToRight
    Caption = #1044#1072#1085#1085#1099#1077' '#1089' '#1055#1059'-1'
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Arial Narrow'
    Font.Style = []
    ParentBiDiMode = False
    ParentFont = False
    Layout = tlCenter
  end
  object l_calendar1: TLabel
    Left = 279
    Top = 607
    Width = 25
    Height = 20
    Alignment = taRightJustify
    AutoSize = False
    Caption = #1089':'
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial Narrow'
    Font.Style = []
    ParentFont = False
  end
  object l_calendar2: TLabel
    Left = 279
    Top = 639
    Width = 25
    Height = 20
    Alignment = taRightJustify
    AutoSize = False
    Caption = #1087#1086':'
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial Narrow'
    Font.Style = []
    ParentFont = False
  end
  object Panel1: TPanel
    Left = 8
    Top = 295
    Width = 978
    Height = 105
    Caption = 'Panel1'
    Ctl3D = True
    ParentCtl3D = False
    ShowCaption = False
    TabOrder = 10
    object Label8: TLabel
      Left = 7
      Top = 9
      Width = 242
      Height = 24
      AutoSize = False
      Caption = #1042#1079#1074#1077#1096#1080#1074#1072#1077#1084#1099#1081' '#1089#1083#1080#1090#1086#1082':'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Arial Narrow'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
    end
    object l_steel_group: TLabel
      Left = 684
      Top = 69
      Width = 184
      Height = 24
      Alignment = taCenter
      AutoSize = False
      Caption = #1055#1083#1072#1085#1086#1074#1099#1081' '#1091#1076'.'#1088#1072#1089#1093'.('#1090'/'#1090')'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = 16685313
      Font.Height = -19
      Font.Name = 'Arial Narrow'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
    end
    object Label1: TLabel
      Left = 684
      Top = 39
      Width = 184
      Height = 24
      Alignment = taCenter
      AutoSize = False
      Caption = #1055#1083#1072#1085#1086#1074#1099#1081' '#1091#1076'.'#1088#1072#1089#1093'.('#1090'/'#1090')'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial Narrow'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
    end
    object Label3: TLabel
      Left = 438
      Top = 39
      Width = 184
      Height = 24
      Alignment = taCenter
      AutoSize = False
      Caption = #1052#1072#1089#1089#1072' '#1089#1083#1080#1090#1082#1072' '#1055#1059'-1('#1090')'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial Narrow'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
    end
    object l_weight_ingot: TLabel
      Left = 438
      Top = 69
      Width = 184
      Height = 24
      Alignment = taCenter
      AutoSize = False
      Caption = #1052#1072#1089#1089#1072' '#1089#1083#1080#1090#1082#1072' '#1055#1059'-1('#1090')'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = 16685313
      Font.Height = -19
      Font.Name = 'Arial Narrow'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
    end
    object l_name: TLabel
      Left = 273
      Top = 69
      Width = 120
      Height = 24
      Alignment = taCenter
      AutoSize = False
      Caption = #1052#1072#1088#1082#1072' '#1089#1090#1072#1083#1080
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = 16685313
      Font.Height = -19
      Font.Name = 'Arial Narrow'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
    end
    object Label4: TLabel
      Left = 273
      Top = 39
      Width = 120
      Height = 24
      Alignment = taCenter
      AutoSize = False
      Caption = #1052#1072#1088#1082#1072' '#1089#1090#1072#1083#1080
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial Narrow'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
    end
    object Label2: TLabel
      Left = 129
      Top = 39
      Width = 120
      Height = 24
      Alignment = taCenter
      AutoSize = False
      Caption = #8470' '#1055#1083#1072#1074#1082#1080
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial Narrow'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
    end
    object l_num_heat: TLabel
      Left = 129
      Top = 69
      Width = 120
      Height = 24
      Alignment = taCenter
      AutoSize = False
      Caption = #8470' '#1055#1083#1072#1074#1082#1080
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = 16685313
      Font.Height = -19
      Font.Name = 'Arial Narrow'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
    end
    object l_datetime: TLabel
      Left = 2
      Top = 69
      Width = 90
      Height = 24
      Alignment = taCenter
      AutoSize = False
      Caption = #1042#1088#1077#1084#1103
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = 16685313
      Font.Height = -19
      Font.Name = 'Arial Narrow'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
    end
    object Label9: TLabel
      Left = 2
      Top = 39
      Width = 90
      Height = 24
      Alignment = taCenter
      AutoSize = False
      Caption = #1042#1088#1077#1084#1103
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial Narrow'
      Font.Style = []
      ParentFont = False
      Layout = tlCenter
    end
    object Panel2: TPanel
      Left = 16
      Top = 216
      Width = 185
      Height = 41
      Caption = 'Panel2'
      TabOrder = 0
    end
  end
  object Button1: TButton
    Left = 865
    Top = 639
    Width = 121
    Height = 26
    Caption = #1086#1073#1085#1086#1074#1080#1090#1100' DBGrid'
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Arial Narrow'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    Visible = False
    WordWrap = True
    OnClick = Button1Click
  end
  object Button4: TButton
    Left = 865
    Top = 607
    Width = 121
    Height = 26
    Caption = #1074#1077#1089' '#1090#1077#1089#1090' '#1079#1072#1087#1080#1089#1080
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Arial Narrow'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    Visible = False
    WordWrap = True
    OnClick = Button4Click
  end
  object DBGrid2: TDBGrid
    Left = 8
    Top = 416
    Width = 978
    Height = 167
    DataSource = DataModule2.DataSource1
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = '@Arial Unicode MS'
    Font.Style = []
    Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgAlwaysShowSelection, dgConfirmDelete, dgCancelOnExit, dgTitleClick, dgTitleHotTrack]
    ParentFont = False
    ReadOnly = True
    TabOrder = 7
    TitleFont.Charset = RUSSIAN_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = '@Arial Unicode MS'
    TitleFont.Style = []
    Touch.ParentTabletOptions = False
    Touch.TabletOptions = [toPressAndHold]
    Columns = <
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'datetime'
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial Narrow'
        Font.Style = []
        Title.Alignment = taCenter
        Title.Caption = #1042#1088#1077#1084#1103
        Title.Font.Charset = RUSSIAN_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -13
        Title.Font.Name = 'Arial Narrow'
        Title.Font.Style = []
        Width = 123
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'num_heat'
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial Narrow'
        Font.Style = []
        Title.Alignment = taCenter
        Title.Caption = #8470' '#1055#1083#1072#1074#1082#1080
        Title.Font.Charset = RUSSIAN_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -13
        Title.Font.Name = 'Arial Narrow'
        Title.Font.Style = []
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'name'
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial Narrow'
        Font.Style = []
        Title.Alignment = taCenter
        Title.Caption = #1052#1072#1088#1082#1072' '#1089#1090#1072#1083#1080
        Title.Font.Charset = RUSSIAN_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -13
        Title.Font.Name = 'Arial Narrow'
        Title.Font.Style = []
        Width = 72
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'mass_ingot'
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial Narrow'
        Font.Style = []
        Title.Alignment = taCenter
        Title.Caption = #1052#1072#1089#1089#1072' '#1089#1083#1080#1090#1082#1072' '#1055#1059'-1 ('#1090')'
        Title.Font.Charset = RUSSIAN_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -13
        Title.Font.Name = 'Arial Narrow'
        Title.Font.Style = []
        Width = 101
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'mass'
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial Narrow'
        Font.Style = []
        Title.Alignment = taCenter
        Title.Caption = #1052#1072#1089#1089#1072' '#1073#1083#1102#1084#1072' ('#1090')'
        Title.Font.Charset = RUSSIAN_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -13
        Title.Font.Name = 'Arial Narrow'
        Title.Font.Style = []
        Width = 85
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'mass_difference'
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial Narrow'
        Font.Style = []
        Title.Alignment = taCenter
        Title.Caption = #1056#1072#1079#1085#1080#1094#1072' '#1084#1072#1089#1089' ('#1090')'
        Title.Font.Charset = RUSSIAN_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -13
        Title.Font.Name = 'Arial Narrow'
        Title.Font.Style = []
        Width = 98
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'p_s_c'
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial Narrow'
        Font.Style = []
        Title.Alignment = taCenter
        Title.Caption = #1055#1083#1072#1085#1086#1074#1099#1081' '#1091#1076#1077#1083#1100#1085#1099#1081' '#1088#1072#1089#1093#1086#1076' ('#1090'/'#1090')'
        Title.Font.Charset = RUSSIAN_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -13
        Title.Font.Name = 'Arial Narrow'
        Title.Font.Style = []
        Width = 96
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'a_s_c'
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial Narrow'
        Font.Style = []
        Title.Alignment = taCenter
        Title.Caption = #1060#1072#1082#1090#1080#1095#1077#1089#1082#1080#1081' '#1091#1076#1077#1083#1100#1085#1099#1081' ('#1090'/'#1090')'
        Title.Font.Charset = RUSSIAN_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -13
        Title.Font.Name = 'Arial Narrow'
        Title.Font.Style = []
        Width = 66
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'aberration'
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial Narrow'
        Font.Style = []
        Title.Alignment = taCenter
        Title.Caption = #1054#1090#1082#1083#1086#1085#1077#1085#1080#1077' '#1086#1090' '#1085#1086#1088#1084#1099' (+/-,'#1090')'
        Title.Font.Charset = RUSSIAN_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -13
        Title.Font.Name = 'Arial Narrow'
        Title.Font.Style = []
        Width = 106
        Visible = True
      end>
  end
  object b_report_detailed: TButton
    Left = 446
    Top = 671
    Width = 140
    Height = 26
    Caption = #1044#1077#1090#1072#1083#1100#1085#1099#1081' '#1086#1090#1095#1077#1090
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Arial Narrow'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
    OnClick = b_report_detailedClick
  end
  object b_report_heat: TButton
    Left = 446
    Top = 607
    Width = 140
    Height = 26
    Caption = #1054#1090#1095#1077#1090' '#1087#1086' '#1087#1083#1072#1074#1082#1077
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Arial Narrow'
    Font.Style = []
    ParentFont = False
    TabOrder = 3
    OnClick = b_report_heatClick
  end
  object DateTimeEnd: TDateTimePicker
    Left = 310
    Top = 639
    Width = 113
    Height = 26
    Date = 0.434715162038628500
    Time = 0.434715162038628500
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Arial Narrow'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
  end
  object DateTimeStart: TDateTimePicker
    Left = 310
    Top = 607
    Width = 113
    Height = 26
    Date = 0.434715162038628500
    Time = 0.434715162038628500
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Arial Narrow'
    Font.Style = []
    ParentFont = False
    TabOrder = 5
  end
  object DBGrid1: TDBGrid
    Left = 8
    Top = 152
    Width = 457
    Height = 121
    DataSource = DataModule2.ib_datasource
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgAlwaysShowSelection, dgConfirmDelete, dgCancelOnExit, dgTitleClick, dgTitleHotTrack]
    ParentFont = False
    ReadOnly = True
    TabOrder = 6
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
    Columns = <
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'time_ingot'
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial Narrow'
        Font.Style = []
        Title.Alignment = taCenter
        Title.Caption = #1042#1088#1077#1084#1103
        Title.Font.Charset = RUSSIAN_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -13
        Title.Font.Name = 'Arial Narrow'
        Title.Font.Style = []
        Width = 72
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'NUM_HEAT'
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial Narrow'
        Font.Style = []
        Title.Alignment = taCenter
        Title.Caption = #8470' '#1055#1083#1072#1074#1082#1080
        Title.Font.Charset = RUSSIAN_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -13
        Title.Font.Name = 'Arial Narrow'
        Title.Font.Style = []
        Width = 108
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'NAME'
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial Narrow'
        Font.Style = []
        Title.Alignment = taCenter
        Title.Caption = #1052#1072#1088#1082#1072' '#1089#1090#1072#1083#1080
        Title.Font.Charset = RUSSIAN_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -13
        Title.Font.Name = 'Arial Narrow'
        Title.Font.Style = []
        Width = 104
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'WEIGHT_INGOT'
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial Narrow'
        Font.Style = []
        Title.Alignment = taCenter
        Title.Caption = #1052#1072#1089#1089#1072' '#1089#1083#1080#1090#1082#1072' '#1055#1059'-1 ('#1090')'
        Title.Font.Charset = RUSSIAN_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -13
        Title.Font.Name = 'Arial Narrow'
        Title.Font.Style = []
        Width = 131
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'STEEL_GROUP'
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial Narrow'
        Font.Style = []
        Title.Font.Charset = RUSSIAN_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -13
        Title.Font.Name = 'Arial Narrow'
        Title.Font.Style = []
        Visible = False
      end>
  end
  object b_selected: TButton
    Left = 471
    Top = 247
    Width = 140
    Height = 26
    Caption = #1042#1079#1074#1077#1096#1080#1074#1072#1077#1084#1099#1081' '#1089#1083#1080#1090#1086#1082
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Arial Narrow'
    Font.Style = []
    ParentFont = False
    TabOrder = 8
    OnClick = b_selectedClick
  end
  object b_report_steel: TButton
    Left = 446
    Top = 639
    Width = 140
    Height = 26
    Caption = #1054#1090#1095#1077#1090' '#1087#1086' '#1084#1072#1088#1082#1077' '#1089#1090#1072#1083#1080
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Arial Narrow'
    Font.Style = []
    ParentFont = False
    TabOrder = 9
    OnClick = b_report_steelClick
  end
  object p_head: TPanel
    Left = 8
    Top = 16
    Width = 978
    Height = 83
    Caption = 'p_head'
    ShowCaption = False
    TabOrder = 11
    object l_current_shift1: TLabel
      Left = 612
      Top = 20
      Width = 264
      Height = 42
      AutoSize = False
      Caption = 'l_current_shift1'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = 16685313
      Font.Height = -35
      Font.Name = 'Arial Narrow'
      Font.Style = []
      ParentFont = False
    end
    object l_sql_work1: TLabel
      Left = 7
      Top = 13
      Width = 218
      Height = 18
      AutoSize = False
      Caption = 'l_sql_work1'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial Narrow'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object l_work_p1: TLabel
      Left = 7
      Top = 45
      Width = 218
      Height = 18
      AutoSize = False
      Caption = 'l_work_p1'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial Narrow'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object l_sql_work2: TLabel
      Left = 256
      Top = 13
      Width = 137
      Height = 18
      AutoSize = False
      Caption = 'l_sql_work2'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clGreen
      Font.Height = -16
      Font.Name = 'Arial Narrow'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object l_work_p2: TLabel
      Left = 256
      Top = 45
      Width = 137
      Height = 18
      AutoSize = False
      Caption = 'l_work_p2'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clGreen
      Font.Height = -16
      Font.Name = 'Arial Narrow'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object l_current_shift2: TLabel
      Left = 900
      Top = 20
      Width = 48
      Height = 42
      AutoSize = False
      Caption = 'l_current_shift2'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = 16685313
      Font.Height = -35
      Font.Name = 'Arial Narrow'
      Font.Style = []
      ParentFont = False
    end
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 500
    OnTimer = Timer1Timer
    Left = 16
    Top = 640
  end
  object ApdComPort1: TApdComPort
    ComNumber = 1
    Baud = 9600
    Parity = pEven
    TraceName = 'APRO.TRC'
    LogName = 'APRO.LOG'
    LogHex = False
    Left = 72
    Top = 640
  end
  object ApdDataPacket1: TApdDataPacket
    Enabled = True
    EndCond = [ecString]
    StartString = '#2'
    EndString = '#3'
    ComPort = ApdComPort1
    PacketSize = 0
    OnStringPacket = ApdDataPacket1StringPacket
    Left = 152
    Top = 640
  end
end
