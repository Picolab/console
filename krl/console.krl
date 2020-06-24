ruleset console {
  meta {
    shares __testing, rs
  }
  global {
    __testing = { "queries":
      [ { "name": "__testing" }
      ] , "events":
      [ { "domain": "console", "type": "expr", "attrs": [ "expr" ] }
      ]
    }
    um = <<
      use module io.picolabs.wrangler alias wrangler
      use module io.picolabs.subscription alias subs
      use module io.picolabs.visual_params alias v_p
    >>
    mt = <<
      meta {#{um}shares result
      }
    >>
    rs = function(expr){
      rsn = random:uuid();
      e = expr.math:base64decode();
      <<ruleset #{rsn}{
#{mt}
  global {
    result=function(){
      #{e}
    }
  }
}>>
    }
  }
  rule create_child_pico {
    select when console expr
    pre {
      expr = event:attr("expr")
    }
    if expr then noop()
    fired {
      raise wrangler event "new_child_request" attributes {
        "name": random:uuid(), "rids": [meta:rid],
        "expr": expr
      }
    }
  }
  rule evaluate_expression {
    select when wrangler new_child_created
      where event:attr("rids") >< meta:rid
    pre {
      expr = event:attr("rs_attrs"){"expr"} || event:attr("expr")
      e = expr.math:base64encode().replace(re#[+]#g,"-")
      eci = event:attr("eci")
      url = <<#{meta:host}/sky/cloud/#{eci}/console/rs.txt?expr=#{e}>>
      picoId = event:attr("id")
    }
    if expr then
    every {
      engine:registerRuleset(url=url) setting(rid)
      engine:installRuleset(picoId,rid=rid)
      http:get(<<#{meta:host}/sky/cloud/#{eci}/#{rid}/result>>) setting(res)
      send_directive("_txt",{"content":res{"content"}})
      engine:uninstallRuleset(picoId,rid)
      engine:unregisterRuleset(rid)
    }
    always {
      raise wrangler event "child_deletion" attributes event:attrs
    }
  }
}
