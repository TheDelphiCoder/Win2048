program Win2048;

uses
  Vcl.Forms,
  u2048 in 'u2048.pas' {frmWin2048};

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := true;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmWin2048, frmWin2048);
  Application.Run;
end.
