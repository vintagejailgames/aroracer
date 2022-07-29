Program conversor;

uses crt;

var
 source, dest : array[0..1023] of byte;
 index:byte;
 f: file;

Procedure LoadTile(arxiu : string);
begin
assign(f, arxiu);
reset(f,1);
blockread(f,source,1024);
close(f);
end;

Procedure SaveTile(arxiu : string);
begin
assign(f, arxiu);
rewrite(f,1);
blockwrite(f,dest,1024);
close(f);
end;

Procedure ConvertTile;
var
  index : word;
  x,y   : byte;
begin
index := 0;
For y:= 15 downto 0 do
  begin
  For x := 16 to 31 do begin dest[index] := source[(y*32)+x]; inc(index); end;
  For x := 0  to 15 do begin dest[index] := source[(y*32)+x]; inc(index); end;
  end;
For y:= 31 downto 16 do
  begin
  For x := 16 to 31 do begin dest[index] := source[(y*32)+x]; inc(index); end;
  For x := 0  to 15 do begin dest[index] := source[(y*32)+x]; inc(index); end;
  end;
end;

var
  i : byte;

begin

If ParamCount < 1 then halt;
For i := 1 to ParamCount do
  begin
  LoadTile(ParamStr(i));
  write('Convertint '+ParamStr(i)+'...');
  ConvertTile;
  SaveTile(ParamStr(i));
  writeln('OK.');
  end;

Writeln;
Writeln('Tots els arxius processats.');
repeat until keypressed;

end.