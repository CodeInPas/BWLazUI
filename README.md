## BWLazUI  

**BWLazUI** is a modern Bootstrap-inspired UI component library for **Lazarus Free Pascal (FPC)** powered by **BGRABitmap**. This package is designed to bring a clean, elegant desktop user interface with full support for rounded corners and alpha blending without any dark border artifacts.

---

## 🚀 Key Features

* **Modern Bootstrap Aesthetic:** Bring modern web design aesthetics into your native Pascal desktop applications.
* **Powered by BGRABitmap:** All components are rendered with high-level anti-aliasing for sharp and smooth visuals.
* **Seamless Transparency:** Fully supports full alpha blending that blends smoothly with background forms.
* **Rich Component Collection:**
  * **BsButton:** Custom interactive buttons with various theme styles.
  * **BsChart:** Multifunctional analytics charts (Bar, Line, Pie, Donut, and Gauge charts).
  * **BsProgressBar:** Smooth and responsive progress indicators.
  * **BsToast:** Elegant pop-up notification system.
  * **BsPagination:** Clean and interactive page navigation.
  * **BsScrollSpy:** Screen scroll monitoring utility.

---

## 📦 System Requirements

Before installing this package, make sure you have installed:
1. **Lazarus IDE** (latest version recommended with Object Pascal / FPC `objfpc` mode).
2. **BGRABitmap Library** (ensure it is installed in your Lazarus environment).

---

## 🛠️ Installation Guide

1. Download or clone this repository to your computer.
2. Open the **Lazarus IDE**.
3. Go to the menu **Package** -> **Open Package File (.lpk)**.
4. Browse and select the `BootstrapUI.lpk` file from the repository directory.
5. In the Package Inspector window, click **Compile**, then choose **Use** -> **Install**.
6. Confirm to rebuild Lazarus. Once restarted, the components will appear under the *BootstrapUI* tab in the Component Palette.

---

## 💡 Usage Example

Drop any component onto your Form and configure its properties directly via the Object Inspector, or customize them dynamically through code:

```pascal
// Dynamically adding data to BsChart
BsChart1.AddData('January', 45);
BsChart1.AddData('February', 80);

```

---

## 🤝 Contribution

Contributions, suggestions, and bug reports are very welcome! Feel free to open an Issue or submit a Pull Request in this repository.

---

## 📄 License

This project is open-source under the [MIT License](https://www.google.com/search?q=LICENSE). Feel free to use it for personal or commercial projects.

## 🙌 Acknowledgments

* [Bootstrap CSS](https://getbootstrap.com/) - For the incredible design system inspiration, color palettes, and aesthetics.
* [BGRABitmap](https://wiki.freepascal.org/BGRABitmap) - An amazing graphics library that enables transparent rendering and anti-aliasing in Lazarus.
* [streamlinehq](https://www.streamlinehq.com/icons/bootstrap-icons?icon=ico_JVo7DRhA8NbbqQML) - Visual icon references for the Component Palette.


