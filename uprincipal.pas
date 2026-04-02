unit uprincipal;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  EditBtn, Process, inifiles, LCLIntF {$IFDEF WIN64}, Windows {$ENDIF};

type

  { TForm_Principal }

  TForm_Principal = class(TForm)
    btn_baixar: TButton;
    btn_salvar: TButton;
    Check_Sem_Audio: TCheckBox;
    Check_MP3: TCheckBox;
    Edit_Pasta_Baixar: TDirectoryEdit;
    Edit_Endereco: TEdit;
    Edit_Pasta: TEdit;
    group_pasta_baixar: TGroupBox;
    group_endereco: TGroupBox;
    group_pasta_arquivos: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    pg_control: TPageControl;
    Baixar: TTabSheet;
    Configuracoes: TTabSheet;
    procedure btn_baixarClick(Sender: TObject);
    procedure btn_salvarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure AbrirPasta(const Pasta: string);
    function sebaixou(endereco: string): boolean;
    Function Escreve_Arq(NomeArq,Texto : String ) : Boolean;
  private

  public

  end;

var
  Form_Principal: TForm_Principal;
  Pasta_Baixar: string;
  versao: string;

implementation

{$R *.lfm}

{ TForm_Principal }

procedure TForm_Principal.btn_baixarClick(Sender: TObject);
var
  parametros: string;
  endereco, pasta: string;
  f, f1: textfile;
  AProcess: TProcess;
begin
  //Verifica se ja foi feito o download deste video e avisa.
  if not FileExists('paginas.txt') then
  begin
    AssignFile(f, 'paginas.txt');
    {$I-}
      Reset(f);
    {$I+}
    if (IOResult <> 0) then
    begin
      Rewrite(f); { arquivo não existe e será criado }
      Append(f);
      closefile(f);
    end
    else
    begin
      CloseFile(f);
    end;
  end;

  //Pasta para baixar e endereço
  pasta := Edit_Pasta.Text;
  endereco := Edit_Endereco.Text;

  // Verifica se o endereço de baixar o arquivo ja exite
  if sebaixou(endereco) then
   if messagedlg('Você ja baixou deste endereço, deseja baixar outra vez?',mtinformation, [mbyes, mbno],0) = mrno then exit;

  // Parametros para ser utilizado no YT-DLP
  {$IFDEF WIN32}
  if Check_MP3.Checked  then parametros := string('--extract-audio --audio-format mp3 --ignore-errors -o  '+'"'+Edit_Pasta_Baixar.Text+'\'+pasta+'\%(title)s.mp4'+'" '+Edit_Endereco.Text)
  else
//  if Check_Sem_Audio.Checked then parametros := string('-f "bv+ba/b" --downloader ffmpeg -i --downloader-args "ffmpeg:-vn" --ignore-errors -o  '+'"'+Edit_Pasta_Baixar.Text+'\'+pasta+'\%(title)s.mp4'+'" '+Edit_Endereco.Text)
  if Check_Sem_Audio.Checked then parametros := string('-f "bestvideo[height<=720]" --merge-output-format mp4 --ignore-errors -o  '+'"'+Edit_Pasta_Baixar.Text+'\'+pasta+'\%(title)s.mp4'+'" '+Edit_Endereco.Text)
  else
  parametros := string('-f "bestvideo[height<=720]+bestaudio/best[height<=720]" --merge-output-format mp4 --ignore-errors -o "'+Edit_Pasta_Baixar.Text+'\'+pasta+'\%(title)s.mp4'+'" '+Edit_Endereco.Text);
  {$ENDIF}
  {$IFDEF LINUX}
  if Check_MP3.Checked  then parametros := string('--extract-audio --audio-format mp3 --ignore-errors -o  '+'"'+Edit_Pasta_Baixar.Text+'/'+pasta+'/%(title)s.mp4'+'" '+Edit_Endereco.Text)
  else
//  if Check_Sem_Audio.Checked then parametros := string('-f "bv+ba/b" --downloader ffmpeg -i --downloader-args "ffmpeg:-vn" --ignore-errors -o  '+'"'+Edit_Pasta_Baixar.Text+'/'+pasta+'/%(title)s.mp4'+'" '+Edit_Endereco.Text)
  if Check_Sem_Audio.Checked then parametros := string('-f "bestvideo[height<=720]" --merge-output-format mp4 --ignore-errors -o  '+'"'+Edit_Pasta_Baixar.Text+'/'+pasta+'/%(title)s.mp4'+'" '+Edit_Endereco.Text)
  else
  parametros := string('-f "bestvideo[height<=720]+bestaudio/best[height<=720]" --merge-output-format mp4 --ignore-errors -o "'+Edit_Pasta_Baixar.Text+'/'+pasta+'/%(title)s.mp4'+'" '+Edit_Endereco.Text);
  {$ENDIF}
  // Mostra os parametros para execução do yt-dlp
  //showmessage(parametros);

  // Executando o YT-DLP

  // Agora nós criaremos o objeto TProcess, e
  // associamos ele à variável AProcess.
  AProcess:=TProcess.Create(nil);

  // Nós definiremos uma opção para onde o programa
  // é executado. Esta opção verificará que nosso programa
  // não continue enquanto o programa que nós executamos
  // não pare de executar.               vvvvvvvvvvvvvv
  AProcess.Options := AProcess.Options + [poNewConsole];

  // Mostraremos ao novo AProcess qual é o comando para ele executar.
  // Vamos usar o Compilador FreePascal
  {$IFDEF WIN32}
    AProcess.CommandLine := 'yt-dlp.exe';
    AProcess.execute;
  {$ENDIF}
  {$IFDEF WIN64}
    AProcess.CommandLine := 'yt-dlp.exe '+ parametros;
    AProcess.execute;

    //Espera um tempo até começar a baixar o yt-dlp
    sleep(15000);

    // Escreve no arquivo paginas as paginas que foram colocadas para baixar
    Escreve_Arq('paginas.txt', datetostr(now)+'-'+timetostr(now)+' - '+ Edit_Pasta.Text+' - '+endereco);

    //Espera 5 segundos para que crie a pasta

    //Verifica se o arquivo paginas existe dentro da pasta onde vai o video
    //  sleep(20000);
    if not FileExists(Pasta_Baixar+'\'+Edit_Pasta.Text+'\paginas.txt') then
    begin
      //    showmessage(Pasta_Baixar+'\'+Edit_Pasta.Text+'\paginas.txt');
      AssignFile(f1,Pasta_Baixar+'\'+Edit_Pasta.Text+'\paginas.txt');
      {$I-}
      Reset(f1);
      {$I+}
      if (IOResult <> 0) then
      begin
        Rewrite(f1); { arquivo não existe e será criado }
        Append(f1);
        closefile(f1);
      end
      else
      begin
        CloseFile(f1);
      end;
    end;

     // Escreve no arquivo paginas que esta dentro da pasta do video
    Escreve_Arq(Pasta_Baixar+'\'+Edit_Pasta.Text+'\paginas.txt', datetostr(now)+'-'+timetostr(now)+' - '+ Edit_Pasta.Text +' - '+endereco);

    if MessageDlg('Deseja abrir a pasta '+Edit_Pasta.Text, mtInformation, [mbyes,mbno], 0) = mrYes then
    begin
      AbrirPasta(Pasta_Baixar+'\'+Edit_Pasta.Text+'\');
    end;
  {$ENDIF}
  {$IFDEF LINUX}
    AProcess.CommandLine := 'yt-dlp '+ parametros;
    AProcess.execute;

    //Espera um tempo até começar a baixar o yt-dlp
    sleep(15000);

    // Escreve no arquivo paginas as paginas que foram colocadas para baixar
    Escreve_Arq('paginas.txt', datetostr(now)+'-'+timetostr(now)+' - '+ Edit_Pasta.Text+' - '+endereco);

    //Espera 5 segundos para que crie a pasta

    //Verifica se o arquivo paginas existe dentro da pasta onde vai o video
    //  sleep(20000);
    if not FileExists(Pasta_Baixar+'/'+Edit_Pasta.Text+'/paginas.txt') then
    begin
      //    showmessage(Pasta_Baixar+'\'+Edit_Pasta.Text+'\paginas.txt');
      AssignFile(f1,Pasta_Baixar+'/'+Edit_Pasta.Text+'/paginas.txt');
      {$I-}
      Reset(f1);
      {$I+}
      if (IOResult <> 0) then
      begin
        Rewrite(f1); { arquivo não existe e será criado }
        Append(f1);
        closefile(f1);
      end
      else
      begin
        CloseFile(f1);
      end;
    end;

     // Escreve no arquivo paginas que esta dentro da pasta do video
    Escreve_Arq(Pasta_Baixar+'/'+Edit_Pasta.Text+'/paginas.txt', datetostr(now)+'-'+timetostr(now)+' - '+ Edit_Pasta.Text +' - '+endereco);

    if MessageDlg('Deseja abrir a pasta '+Edit_Pasta.Text, mtInformation, [mbyes,mbno], 0) = mrYes then
    begin
      AbrirPasta(Pasta_Baixar+'/'+Edit_Pasta.Text+'/');
    end;
  {$ENDIF}

  // Limpa edit de endereço
  Edit_Endereco.Clear;

end;

procedure TForm_Principal.btn_salvarClick(Sender: TObject);
var
  IniFile: TIniFile;
begin
 IniFile := TIniFile.Create('IBaixar.ini');
  try
    IniFile.WriteString('iBaixar', 'Pasta_Baixar', Edit_Pasta_Baixar.Text);
  finally
    IniFile.Free;
  end;

  label1.Caption := 'Local de gravação: '+Edit_Pasta_Baixar.Text;
  pasta_baixar := Edit_Pasta_Baixar.Text;

  pg_control.TabIndex:=0;
end;

procedure TForm_Principal.FormCreate(Sender: TObject);
var
  parametros: string;
  AProcess: TProcess;
begin
  //Verifica se esta atualizado e atualiza se não estiver.
  parametros := string('--update');

  // Executando o YT-DLP

  // Agora nós criaremos o objeto TProcess, e
  // associamos ele à variável AProcess.
  AProcess:=TProcess.Create(nil);

  // Mostraremos ao novo AProcess qual é o comando para ele executar.
  // Vamos usar o Compilador FreePascal
  {$IFDEF WIN32}
    AProcess.CommandLine := 'yt-dlp.exe';
    AProcess.execute;
  {$ENDIF}
  {$IFDEF WIN64}
    AProcess.CommandLine := 'yt-dlp.exe '+ parametros;
    AProcess.execute;
    AProcess.Destroy;
  {$ENDIF}
  {$IFDEF LINUX}
    AProcess.CommandLine := 'sudo yt-dlp '+ parametros;
    AProcess.execute;
    AProcess.Destroy;
  {$ENDIF}
end;

procedure TForm_Principal.FormShow(Sender: TObject);
var
  IniFile: TIniFile;
  ValorLido: string;
begin
  // Ler ini
  IniFile := TIniFile.Create('iBaixar.ini');
  try
    ValorLido := IniFile.ReadString('iBaixar', 'Pasta_Baixar','');
    Pasta_Baixar := IniFile.ReadString('iBaixar', 'Pasta_Baixar','');
    Edit_Pasta_Baixar.Text := Pasta_Baixar;
//    ShowMessage('Valor lido: ' + ValorLido );
  finally
    IniFile.Free;
  end;

  //  Check_limpar_pasta.Checked := False;
  //Pergar configurações de um arquivo ini
  //* Pasta onde ira ser colocado os donwloads

  // Versão do aplicativo
  versao := 'L2.20260402.1';
  label1.Caption := 'Local de gravação: '+pasta_baixar;
  label2.Caption := 'iBaixar '+versao;
end;

function TForm_Principal.sebaixou(endereco: string): boolean;
begin
  with TStringList.Create do begin
    LoadFromFile('paginas.txt');
    if(Pos(endereco,Text)>0)then
    begin
        result := true;
       //true Sim tem a palavra
    end;
  end;
end;

procedure TForm_Principal.AbrirPasta(const Pasta: string);
var
  AbrirProcess: TProcess;
begin
{
  // Parametros para ser utilizado no YT-DLP
  parametros := string('-f "bestvideo[height<=720]+bestaudio/best[height<=720]" --merge-output-format mp4 --ignore-errors -o "'+Edit_Pasta_Baixar.Text+'\'+pasta+'\%(title)s.mp4'+'" '+Edit_Endereco.Text);

  // Executando o YT-DLP

  // Agora nós criaremos o objeto TProcess, e
  // associamos ele à variável AProcess.
  AProcess:=TProcess.Create(nil);

  // Nós definiremos uma opção para onde o programa
  // é executado. Esta opção verificará que nosso programa
  // não continue enquanto o programa que nós executamos
  // não pare de executar.               vvvvvvvvvvvvvv
  AProcess.Options := AProcess.Options + [poNewConsole]; }

  {$IFDEF WIN64}
  ShellExecute(0, 'open', PChar(Pasta), nil, nil, SW_SHOWNORMAL);
  {$ENDIF}
  {$IFDEF LINUX}
  OpenDocument(PChar(Pasta));
  {$ENDIF}
end;

Function TForm_Principal.Escreve_Arq(NomeArq,Texto : String ) : Boolean;
var
   sArquivo : tStrings;
Begin
   Try
     sArquivo:=tStringList.Create;
     sArquivo.LoadFromFile(NomeArq);
     sArquivo.Add(texto);
     sArquivo.SaveToFile(NomeArq);
     result:=True;
   except
     result:=False;
   end
End;

end.

