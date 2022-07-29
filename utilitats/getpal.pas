program GetPal;

uses crt;

type
  GIFHeader = record
    Signature : String [6];
    ScreenWidth,
    ScreenHeight : Word;
    Depth,
    Background,
    Zero : Byte;
  end;
  GIFDescriptor = record
    Separator : Char;
    ImageLeft,
    ImageTop,
    ImageWidth,
    ImageHeight : Word;
    Depth : Byte;
  end;

  RGB = record
    R,G,B: byte;
  end;

  AuxPalette = array [0..255] of RGB;

Procedure get_one(filename,balname:string);
var
  Header       : GIFHeader;
  Descriptor   : GIFDescriptor;
  GIFFile      : File;
  f            : file of AuxPalette;
  Palette      : AuxPalette;
  i, index     : byte;
  source,destination : string;
begin
{ PER A FICAR-HO BONICO EN PANTALLA }
source := '';
repeat inc(index) until filename[index] = '.';
repeat dec(index) until filename[index] = '\'; inc(index);
repeat source := source + filename[index]; inc(index); until filename[index] = '.';
source := source + filename[index]; inc(index);
source := source + filename[index]; inc(index);
source := source + filename[index]; inc(index);source := source + filename[index];

destination:= '';
repeat inc(index) until balname[index] = '.';
repeat dec(index) until balname[index] = '\'; inc(index);
repeat destination := destination + balname[index]; inc(index); until balname[index] = '.';
destination := destination + balname[index]; inc(index);
destination := destination + balname[index]; inc(index);
destination := destination + balname[index]; inc(index);destination := destination + balname[index];



  Write('Agafant ',destination,' de ',source);

  Assign (GIFFile, filename);
  Reset (GIFFile, 1);

  Blockread (GIFFile, Header.Signature [1], sizeof (Header) - 1);

  BlockRead (GIFFile, Palette, 768);
  for i := 0 to 255 do begin
    Palette [i].r := Palette [i].r shr 2;
    Palette [i].g := Palette [i].g shr 2;
    Palette [i].b := Palette [i].b shr 2;
  end;
  Close(GIFFile);

  Assign(f, balname);
  Rewrite(f);
  Write(f,Palette);
  Close(f);

  Writeln('   OK.');
end;

var
  desti : string;
  index : byte;
  i     : byte;

begin
clrscr;
Writeln('Arounders Paleta Conversor');
Writeln('===========================');
Writeln;

If ParamCount < 1 then
  begin
  writeln('Tens que passar-li al menys un arxiu GIF com a paràmetre');
  end
else
  begin
  For i := 1 to ParamCount do
    begin
    index := 0;
    desti := ParamStr(i);
    repeat inc(index) until desti[index] = '.';
    desti[index+1] := 'p';
    desti[index+2] := 'a';
    desti[index+3] := 'l';
    get_one(ParamStr(i), desti);
    end;
  Writeln;
  Writeln('Tots els arxius procesats.');
  end;

end.
