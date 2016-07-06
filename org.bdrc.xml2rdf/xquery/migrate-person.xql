xquery version "3.0";

import module namespace util="http://exist-db.org/xquery/util";

declare namespace f="http://exist-db.org/xquery/file";
declare namespace pin="http://www.tbrc.org/models/person#";
declare namespace p="http://www.tbrc.org/models/person";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns";
declare namespace rdfs="http://www.w3.org/2000/01/rdf-schema";

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

declare function local:has-lang($e as element())
as xs:boolean
{
    local-name($e) = 
        ("name", "description", "title", "catalogInfo", "publisherName", "printery",
         "publisherLocation", "authorshipStatement", "seriesName", "series", "shelf",
         "editionStatement", "biblioNote", "sourceNote")
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
        ("description")
};

declare function local:migrate($input as item()*)
as item()*
{
    for $node in $input
    return 
        typeswitch($node)
        case element()
            return
                if (local-name($node) eq "ofSect") then
                    ()
                else if (local-name($node) eq "incarnationOf") then
                    <p:incarnationOf pid="{ $node/@being }">{ $node/@*[name() != "being"] }</p:incarnationOf>
                else if (local-name($node) eq "kinship") then
                    <p:kinship pid="{ $node/@person }">{ $node/@*[name() != "person"] }</p:kinship>
                else if (local:has-lang1($node)) then
                    let $lang := local:fix-lang($node)
                    let $atts := $node/@*[name() != "lang" and name() != "encoding" and name() != "type-tib"]
                    return
                        element {"p:" || local-name($node)}
                            { $atts, attribute xml:lang { $lang }, local:migrate($node/node()) }
                else if (local:has-lang2($node)) then
                    let $lang := local:fix-lang($node)
                    let $atts := $node/@*[name() != "lang" and name() != "encoding"]
                    return
                        if ($node/@lang) then
                            element {"p:" || local-name($node)}
                                { $atts, attribute xml:lang { $lang }, local:migrate($node/node()) }
                        else
                            element {"p:" || local-name($node)}
                                { $atts, local:migrate($node/node()) }
                else
                    element {"p:" || local-name($node)}
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

declare function local:migrate1($top as item()*)
as item()*
{
    let $pn := $top/pin:name[1]
    let $lang := if ($pn) then local:fix-lang($pn) else "NO_NAME_FOR_" || $top/@RID
    let $lbl := <rdfs:label xml:lang="{ $lang }">{ normalize-space($pn) }</rdfs:label>
    return
        <p:person>{
            $top/@*,
            $lbl,
            for $child in $top/node()
                return 
                    if ($child instance of element()) then
                        local:migrate($child)
                    else 
                        $child
        }</p:person>
};

declare function local:process($outDir as xs:string) 
as item()*
{
    for $p in collection("/db/tbrc/tbrc-persons")/pin:person[@RID="P1583"]
    let $x := local:migrate1($p)
    let $path := $outDir || $x/@RID || ".xml"
    let $ign := util:log("INFO", "Migrated " || $p/@RID || " writing to: " || $path)
    let $ign := f:serialize($x, $path, ())
    return
        ()
};

let $outDir := "/usr/local/BUDA_TECH/MIGRATION/XML_EXPORTED/PERSONS/"
let $ign := local:process($outDir)
return
    "done"
