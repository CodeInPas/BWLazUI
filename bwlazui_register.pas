unit bwlazui_register;

{$mode objfpc}{$H+}
{$R bwlazui.rc} // <-- Tambahan: Memuat resource ikon komponen

interface

uses
  Classes, SysUtils, LazarusPackageIntf,
  bsbutton,
  bschart,
  bscard,
  bsalert,
  bstoast,
  bstooltip,
  bspopover,
  bsdropdown,
  bscollapse,
  bsaccordion,
  bsbreadcrumb,
  bspagination,
  bsnavtabs,
  bsnavbar,
  bsmodal,
  bsoffcanvas,
  bscarousel,
  bsscrollspy,
  bsbadges,
  bsprogress,
  bsspinner,
  bscheckbox,
  bsinput,
  bsdbgrid,
  bsbuttongroup;

procedure Register;

implementation

procedure Register;
begin

  RegisterComponents('BWLazUI', [
  TBsbutton ,
  TBsChart,
  TBscard ,
  TBsalert ,
  TBstoast ,
  TBstooltip ,
  TBspopover,
  TBsdropdown,
  TBscollapse ,
  TBsaccordion,
  TBsbreadcrumb,
  TBspagination ,
  TBsNavTabs ,
  TBsnavbar ,
  TBsmodal ,
  TBsoffcanvas ,
  TBscarousel ,
  TBsscrollspy,
  TBsBadge,
  TBsprogress ,
  TBsspinner ,
  TBscheckbox,
  TBsinput,
  TBsDBGrid,
  TBsbuttongroup ]);

end;

//initialization
//  RegisterPackage('BootstrapUI', @Register);
end.
