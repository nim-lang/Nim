unit Unit1; 

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  Spin, StdCtrls;

type

  { TForm1 }

  TForm1 = class(TForm)
    Edit1: TEdit;
    Label1: TLabel;
    SpinEdit1: TSpinEdit;
    SpinEdit2: TSpinEdit;
    procedure FormCreate(Sender: TObject);
    procedure SpinEdit1Change(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  Form1: TForm1; 

implementation

{ TForm1 }

{$link nimcache/lib/system.o}
{$link nimcache/backend.o}
{$link nimcache/nim__dat.o}
{$linklib c}

procedure NimMain; cdecl; external;
function myAdd(x, y: longint): longint; cdecl; external;

procedure TForm1.FormCreate(Sender: TObject);
begin
  // we initialize the Nimrod data structures here:
  NimMain();
end;

procedure TForm1.SpinEdit1Change(Sender: TObject);
begin
  Edit1.text := IntToStr(myAdd(SpinEdit1.Value, SpinEdit2.Value));
end;

initialization
  {$I unit1.lrs}

end.

