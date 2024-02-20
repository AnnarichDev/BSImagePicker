// The MIT License (MIT)
//
// Copyright (c) 2567 BE NB1003917
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

extension UIFont {
    
    enum Graphik: String {
        
        case bold = "GraphikTH-SemiBold"
        case regular = "GraphikTH-Regular"
    }
        
    public class func graphik(ofSize size: CGFloat, weight: UIFont.Weight = .light, isItalic: Bool = false) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
        
        switch weight {
        case .regular:
            let name = Graphik.regular
            return UIFont(name: name.rawValue, size: size) ?? systemFont
        case .bold:
            let name = Graphik.bold
            return UIFont(name: name.rawValue, size: size) ?? systemFont
        default:
            return systemFont
        }
    }
    
    public class func graphikRegular(ofSize size: CGFloat) -> UIFont {
        return graphik(ofSize: size, weight: .regular)
    }
    
    public class func graphikBold(ofSize size: CGFloat) -> UIFont {
        return graphik(ofSize: size, weight: .bold)
    }
    
    private static func registerFont(withName name: String, fileExtension: String) {
        let frameworkBundle = Bundle(for: ImagePickerController.self)
        let pathForResourceString = frameworkBundle.path(forResource: name, ofType: fileExtension)
        let fontData = NSData(contentsOfFile: pathForResourceString!)
        let dataProvider = CGDataProvider(data: fontData!)
        let fontRef = CGFont(dataProvider!)
        var errorRef: Unmanaged<CFError>? = nil

        if (CTFontManagerRegisterGraphicsFont(fontRef!, &errorRef) == false) {
            print("Error registering font")
        }
    }

    public static func loadFonts() {
        registerFont(withName: Graphik.bold.rawValue, fileExtension: "ttf")
        registerFont(withName: Graphik.regular.rawValue, fileExtension: "ttf")
    }
}

enum BSImagePickerFont {

    /// Graphik - Regular  Size  16
    static let text = UIFont.graphikRegular(ofSize: 16)
    /// Graphik - Bold  Size  16
    static let textBold = UIFont.graphikBold(ofSize: 16)
    /// Graphik - Bold  Size  18
    static let title = UIFont.graphikBold(ofSize: 18)
}

