unit main_form;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, bscarousel,
  bsbreadcrumb, bsdropdown, bsprogress, bspagination, bscollapse, bsaccordion,
  bsbuttongroup, bsnavbar, bsbutton, bsoffcanvas, bschart, bsnavtabs, bspopover,
  bsalert, bstoast, bscard, bsscrollspy;

type

  { TForm1 }

  TForm1 = class(TForm)
    BsAccordion1: TBsAccordion;
    BsAlert1: TBsAlert;
    BsButton1: TBsButton;
    BsButton2: TBsButton;
    BsButton3: TBsButton;
    BsButton4: TBsButton;
    BsChart1: TBsChart;
    BsChart2: TBsChart;
    BsDropdown1: TBsDropdown;
    BsNavbar1: TBsNavbar;
    BsPagination1: TBsPagination;
    BsPopover1: TBsPopover;
    BsProgress1: TBsProgress;
    BsProgress2: TBsProgress;
    BsScrollSpy1: TBsScrollSpy;
    BsToast1: TBsToast;
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

end.

