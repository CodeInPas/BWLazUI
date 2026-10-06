unit bootstrapui_register;

{$mode objfpc}{$H+}
{$R bootstrapui.rc} // <-- Tambahan: Memuat resource ikon komponen

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
  TBsbuttongroup ]);

end;

//initialization
//  RegisterPackage('BootstrapUI', @Register);
end.
