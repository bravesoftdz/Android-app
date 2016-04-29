unit main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Edit,
  FMX.ComboEdit, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Ani, FMX.Maps,
  FMX.WebBrowser, IPPeerClient, REST.Client, Data.Bind.Components,
  Data.Bind.ObjectScope, FMX.Layouts, FMX.ListBox, System.JSON,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  FMX.ListView, FMX.SearchBox, Data.Bind.GenData, System.Rtti,
  System.Bindings.Outputs, Fmx.Bind.Editors, Data.Bind.EngExt, Fmx.Bind.DBEngExt,
  System.Generics.Collections, Data.Bind.Controls,
  Fmx.Bind.Navigator, IdURI, FMX.TabControl, System.Actions, FMX.ActnList,
  System.Sensors, System.Sensors.Components;

type
  TForm1 = class(TForm)
    RESTRequest1: TRESTRequest;
    RESTClient1: TRESTClient;
    RESTResponse1: TRESTResponse;
    onChangeEditTextTimer: TTimer;
    ToolBar1: TToolBar;
    Edit1: TEdit;
    ClearEditButton1: TClearEditButton;
    ListView1: TListView;
    TabControl1: TTabControl;
    Settings: TTabItem;
    Weather: TTabItem;
    TabControl2: TTabControl;
    TabItem1: TTabItem;
    NearBy: TTabItem;
    ActionList1: TActionList;
    gotoWeather: TChangeTabAction;
    gotoSettings: TChangeTabAction;
    ToolBar2: TToolBar;
    Label1: TLabel;
    WebBrowser1: TWebBrowser;
    SpeedButton1: TSpeedButton;
    AniIndicator1: TAniIndicator;
    ToolBar3: TToolBar;
    Label2: TLabel;
    LocationSensor1: TLocationSensor;
    ListView2: TListView;
    onLocationChanged: TTimer;
    AniIndicator2: TAniIndicator;
    Label3: TLabel;
    ListBox1: TListBox;
    ListBoxItem1: TListBoxItem;
    AniIndicator3: TAniIndicator;
    gotoNearBy: TChangeTabAction;
    procedure Edit1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure ListView1ItemClick(const Sender: TObject;
      const AItem: TListViewItem);
    procedure WebBrowser1DidFinishLoad(ASender: TObject);
    procedure LocationSensor1LocationChanged(Sender: TObject; const OldLocation,
      NewLocation: TLocationCoord2D);
    procedure NearByClick(Sender: TObject);
    procedure onLocationChangedTimer(Sender: TObject);
    procedure onChangeEditTextTimerTimer(Sender: TObject);
    procedure ListView2ItemClick(const Sender: TObject;
      const AItem: TListViewItem);
  private
    goFromTab: string;
    oldSearchBoxText: string;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}
{$R *.SmXhdpiPh.fmx ANDROID}
{$R *.LgXhdpiPh.fmx ANDROID}
{$R *.XLgXhdpiTb.fmx ANDROID}
{$R *.NmXhdpiPh.fmx ANDROID}
{$R *.LgXhdpiTb.fmx ANDROID}

procedure setRESTRequestParam(name, value: string);
begin
  try
    Form1.RESTRequest1.Params.ParameterByName(name).Value := value;
  except
    Form1.RESTRequest1.AddParameter(name, value);
  end;
  Form1.RESTRequest1.AddParameter(name, value);
end;

procedure getCityData(ListView: TListView);
var jValue: TJSONValue;
    jArray: TJSONArray;
    json, json1: TJSONObject;
    ListViewItem: TListViewItem;
    region, municipal: string;
    function getStr(json: TJSONObject; value: string): string;
    begin
      try
         Result := json.Get(value).JsonValue.value;
      except
         Result := '';
      end;
    end;
begin
  with Form1 do begin
    RESTRequest1.Execute;
    ListView.Items.Clear;
    AniIndicator2.Visible := false;
    AniIndicator3.Visible := false;
    jValue:=RESTResponse1.JSONValue;
    if (jValue is TJSONObject) then begin
      json :=  TJSONObject(jValue);
      jArray := json.GetValue('items') as TJSONArray;
      for jValue in jArray do
      begin
        json1 :=  TJSONObject(jValue);
        ListViewItem := ListView.Items.Add;
        region := getStr(json1, 'd_name');
        if (region<>'') then  region := ', '+region;
        municipal := getStr(json1, 'mun_name');
        if (municipal<>'') then  municipal := ', '+municipal;
        ListViewItem.Detail := getStr(json1, 'c_name') + region + municipal;
        ListViewItem.Text := json1.Get('name').JsonValue.value;
        ListViewItem.Tag := strToIntDef(getStr(json1, 'id'), 0);
      end;
    end;
  end;
end;

procedure TForm1.Edit1Click(Sender: TObject);
begin
  edit1.Text := '';
  edit1.FontColor := TAlphaColorRec.Black;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  oldSearchBoxText := 'Поиск погоды';
  edit1.Text := oldSearchBoxText;
  edit1.FontColor:= TAlphaColorRec.Darkgray;
end;

procedure TForm1.ListView1ItemClick(const Sender: TObject;
  const AItem: TListViewItem);
begin
  goFromTab := 'search';
  WebBrowser1.Visible := false;
  AniIndicator1.Visible := true;
  gotoWeather.ExecuteTarget(self);
  WebBrowser1.URL := 'http://m.meteonova.ru/frc/'+intToStr(AItem.Tag)+'.html';
  //WebBrowser1.EvaluateJavaScript('renderMarker('+intToStr(AItem.Tag)+');');
end;

procedure TForm1.ListView2ItemClick(const Sender: TObject;
  const AItem: TListViewItem);
begin
  goFromTab := 'nearby';
  WebBrowser1.Visible := false;
  AniIndicator1.Visible := true;
  gotoWeather.ExecuteTarget(self);
  WebBrowser1.URL := 'http://m.meteonova.ru/frc/'+intToStr(AItem.Tag)+'.html';
  //WebBrowser1.EvaluateJavaScript('renderMarker('+intToStr(AItem.Tag)+');');
end;

procedure TForm1.LocationSensor1LocationChanged(Sender: TObject;
  const OldLocation, NewLocation: TLocationCoord2D);
var LDecSeparator: Char;
    LSettings: TFormatSettings;
    URLString: string;
begin
  //LDecSeparator := FormatSettings.DecimalSeparator;
  //LSettings := FormatSettings;
  try
    //FormatSettings.DecimalSeparator := '.';
    RESTRequest1.Params.Clear;
    setRESTRequestParam('searchby', 'cities');
    setRESTRequestParam('lat', Format('%2.6f', [NewLocation.Latitude]));
    setRESTRequestParam('lng', Format('%2.6f', [NewLocation.Longitude]));
    LocationSensor1.Active := false;
    onLocationChanged.Enabled :=true;
  finally
    //FormatSettings.DecimalSeparator := LDecSeparator;
  end;
end;

procedure TForm1.onChangeEditTextTimerTimer(Sender: TObject);
begin
    if  (oldSearchBoxText<>edit1.Text) then
    begin
      oldSearchBoxText := edit1.Text;
      if edit1.Text = '' then exit;
      AniIndicator3.Visible := true;
      setRESTRequestParam('fchar', edit1.Text);
      setRESTRequestParam('mcntcities', '30');
      getCityData(ListView1);
    end;
end;

procedure TForm1.onLocationChangedTimer(Sender: TObject);
begin
  getCityData(ListView2);
  onLocationChanged.Enabled := false;
end;

procedure TForm1.SpeedButton1Click(Sender: TObject);
begin
  if goFromTab = 'search' then
    gotoSettings.ExecuteTarget(self)
  else
    gotoNearBy.ExecuteTarget(self);
end;

procedure TForm1.NearByClick(Sender: TObject);
begin
  AniIndicator2.Visible := true;
  LocationSensor1.Active := true;
end;

procedure TForm1.WebBrowser1DidFinishLoad(ASender: TObject);
begin
  AniIndicator1.Visible := false;
  WebBrowser1.Visible := true;
end;

end.
