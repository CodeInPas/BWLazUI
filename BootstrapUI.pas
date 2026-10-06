{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit BootstrapUI;

{$warn 5023 off : no warning about unused units}
interface

uses
  bstypes, bsthemes, bsgraphics, bsbutton, bscard, bsalert, bstoast, 
  bstooltip, bspopover, bsdropdown, bscollapse, bsaccordion, bsbreadcrumb, 
  bspagination, bsnavtabs, bsnavbar, bsmodal, bscarousel, bsscrollspy, 
  bsbadges, bsprogress, bsspinner, bscheckbox, bsinput, bsclosebutton, 
  bsbuttongroup, bslistgroup, bsplaceholder, bsoffcanvas, 
  bootstrapui_register, bschart, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('bootstrapui_register', @bootstrapui_register.Register);
end;

initialization
  RegisterPackage('BootstrapUI', @Register);
end.
