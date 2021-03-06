// I am truly sorry for this. Look, I never learned generics.
// If you have resources on what I should look into to implement this properly,
// please open an issue!
func classNameRemovingGenerics(_ obj: Any) -> String {
    let classType = type(of: obj)
    let className = String(describing: classType)
    return String(className.split(separator: "<", maxSplits: 1)[0])
}

class DOMEmitter {
    var buffer: String = ""
    func emit(_ tag: String, _ attributes: [String: String]) {
        out("<")
        out(tag)
        out(" ")
        for (name, val) in attributes {
            out(name)
            out("=\"")
            out(val)
            out("\" ")
        }
        out(">")
    }
    func text(_ text: String) {
        // todo escape
        out(text)
    }
    func close(_ tag: String) {
        out("</\(tag)>")
    }
    func out(_ string: String) {
        self.buffer += string
    }
}
func render(view: Any, emitter: DOMEmitter) {
    //print("Rendering", view)
    if String(describing: view) == "nil" {
        return
    }
    if let v = view as? MarinaNavigationViewAccess {
        emitter.emit("div", ["class": "marina-navigationview"])
        render(view: v.getContent(), emitter: emitter)
        emitter.close("div")
        return
    }
    if let v = view as? MarinaListAccess {
        emitter.emit("div", ["class": "marina-list"])
        render(view: v.getContent(), emitter: emitter)
        emitter.close("div")
        return
    }
    if let v = view as? MarinaToggleAccess {
        emitter.emit("div", ["class": "marina-toggle"])
        render(view: v.getContent(), emitter: emitter)
        emitter.close("div")
        return
    }
    if let v = view as? MarinaForEachAccess {
        let data = v.getContent() as! [Any]
        for d in data {
            render(view: d, emitter: emitter)
        }
        return
    }
    if let v = view as? MarinaNavigationButtonAccess {
        emitter.emit("div", ["class": "marina-navigationbutton"])
        render(view: v.getContent(), emitter: emitter)
        emitter.close("div")
        return
    }
    if let _ = view as? MarinaSpacerAccess {
        // nothing
        return
    }
    let className = classNameRemovingGenerics(view)
    //print(_typeName(type(of: view), qualified: true))
    switch className {
        case "HStack":
            emitter.emit("div", ["class": "marina-hstack"])
            let v = view as! MarinaHStackAccess
            render(view: v.getContent(), emitter: emitter)
            emitter.close("div")
        case "VStack":
            emitter.emit("div", ["class": "marina-vstack"])
            let v = view as! MarinaVStackAccess
            render(view: v.getContent(), emitter: emitter)
            emitter.close("div")
        case "ZStack":
            emitter.emit("div", ["class": "marina-zstack"])
            let v = view as! MarinaZStackAccess
            render(view: v.getContent(), emitter: emitter)
            emitter.close("div")
        case "Text":
            emitter.emit("div", ["class": "marina-text"])
            let v = view as! MarinaTextAccess
            emitter.text(v.getContent() as! String)
            emitter.close("div")
        case "TupleView":
            //print("TupleView")
            let v = view as! MarinaTupleViewAccess
            let content = v.getContent()
            let mirror = Mirror(reflecting: content)
            for (_, value) in mirror.children {
                if let innerView = value as? MarinaViewBodyAccessor {
                    render(view: innerView, emitter: emitter)
                }
            }
        case "ConditionalContent":
            //print("ConditionalContent")
            let v = view as! MarinaConditionalContentAccess
            render(view: v.getContent(), emitter: emitter)
        case "Image":
            let v = view as! MarinaImageAccess
            emitter.emit("img", ["class": "marina-image", "src": v.getContent() as! String])
        case "EmptyView":
            do {}
        default:
            //print("Unsupported view type: " + className)
            let v = view as! MarinaViewBodyAccessor
            render(view: v.getBody(), emitter: emitter)
    }
}