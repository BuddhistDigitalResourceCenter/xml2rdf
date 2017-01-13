xquery version "3.0";

declare namespace f="http://exist-db.org/xquery/file";
declare namespace ig="http://www.tbrc.org/models/imagegroup#";
declare namespace pi="http://www.tbrc.org/models/pubinfo#";
declare namespace w="http://www.tbrc.org/models/work#";

declare function local:fix-lang($e as element())
as xs:string
{
    if (not($e/@lang) or $e/@encoding="extendedWylie") then
        "bo-x-exwylie"
    else if ($e/@lang="tibetan") then
        if ($e/@encoding="acip") then
            "bo-x-acip"
        else if ($e/@encoding="tbrcPhonetic") then
            "bo-x-tbrc"
        else if ($e/@encoding="rma") then
            "bo-x-rma"
        else if ($e/@encoding="alternatePhonetic") then
            "bo-x-alt"
        else if ($e/@encoding="libraryOfCongress") then
            "bo-x-loc"
        else
            "bo"
    else if ($e/@lang="chinese") then
        if ($e/@encoding="wadeGiles") then
            "zh-x-wade"
        else if ($e/@encoding="pinyin") then
            "zh-x-pinyin"
        else if ($e/@encoding="libraryOfCongress") then
            "zh-x-loc"
        else
            "zh"
    else if ($e/@lang="english") then
        "en"
    else if ($e/@lang="sanskrit") then
        if ($e/@encoding="libraryOfCongress") then
            "sa-x-loc"
        else if ($e/@encoding="sansDiacritics") then
            "sa-x-sans"
        else if ($e/@encoding="withDiacritics") then
            "sa-x-with"
        else
            "sa"
    else if ($e/@lang="mongolian") then
        "mn"
    else if ($e/@lang="french") then
        "fr"
    else if ($e/@lang="russia") then
        "ru"
    else if ($e/@lang="dzongkha") then
        "dz"
    else if ($e/@lang="german") then
        "de"
    else if ($e/@lang="japanese") then
        "ja"
    else "??"
};

declare function local:has-lang1($e as element())
as xs:boolean
{
    local-name($e) = 
        ( "name", "title" )
};

declare function local:has-lang2($e as element())
as xs:boolean
{
    local-name($e) = 
        ("description", "catalogInfo", "publisherName", "printery",
         "publisherLocation", "authorshipStatement", "seriesName", "series", "shelf",
         "editionStatement", "biblioNote", "sourceNote")
};

declare function local:migrate($input as item()*)
as item()*
{
    for $node in $input
    return 
        typeswitch($node)
        case element()
            return
                if (local:has-lang1($node)) then
                    let $lang := local:fix-lang($node)
                    let $atts := $node/@*[name() != "lang" and name() != "encoding"]
                    return
                        element {"w:" || local-name($node)}
                            { $atts, attribute lang { $lang }, local:migrate($node/node()) }
                else if (local:has-lang2($node)) then
                    let $lang := local:fix-lang($node)
                    let $atts := $node/@*[name() != "lang" and name() != "encoding"]
                    return
                        if ($node/@lang) then
                            element {"w:" || local-name($node)}
                                { $atts, attribute lang { $lang }, local:migrate($node/node()) }
                        else
                            element {"w:" || local-name($node)}
                                { $atts, local:migrate($node/node()) }
                else if (local-name($node) = "hasPubInfo") then
                    let $pi := collection("/db/tbrc/tbrc-pubinfos")/pi:pubinfo[@RID=$node/@info]
                    return
                        local:migrate($pi/node())
                else if (local-name($node) = "isPubInfoFor") then
                    ()
                else if (local-name($node) = "volume") then
                    let $ig := collection("/db/tbrc/tbrc-imagegroups")/ig:imagegroup[@RID=$node/@imagegroup]
                    let $num := $node/@num
                    return
                        element {"w:" || local-name($node)}
                            { $num, local:migrate($ig/node()) }
                else if (local-name($node) = "isVolumeOf") then
                    ()
                else if (local-name($node) = "log" and namespace-uri($node) = "http://www.tbrc.org/models/imagegroup#") then
                    ()
                else if (local-name($node) = "log" and namespace-uri($node) = "http://www.tbrc.org/models/pubinfo#") then
                    ()
                else
                    element {"w:" || local-name($node)}
                        {$node/@*,
                         for $child in $node/node()
                            return 
                                if ($child instance of element()) then
                                    local:migrate($child)
                                else 
                                    $child
                        }
        case text()
            return normalize-space($node)
        (: otherwise pass it through.  Used for text(), comments, and PIs :)
        default 
            return $node
};

declare function local:process($outDir as xs:string) 
as item()*
{
    for $w in collection("/db/tbrc/tbrc-works")/w:work
    let $x := local:migrate($w)
    let $ign := f:serialize($x, $outDir || $x/@RID || ".xml", ())
    return
        ()
};

let $outDir := "/usr/local/BUDA_TECH/MIGRATION/OUT/WORKS/"
let $ign := local:process($outDir)
return
    "done"
