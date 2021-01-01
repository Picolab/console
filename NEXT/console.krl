ruleset console {
  meta {
    use module io.picolabs.wrangler alias wrangler
    shares rs
  }
  global {
    __testing = {
      "queries":
        [ { "rid": meta:rid, "name": "rs", "args": [ "expr" ] }
        ],
      "events":
        [ { "domain": "console", "name": "expr", "attrs": [ "expr" ] }
        ]
    }
    um = <<
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.subscription alias subs
    >>
    mt = <<meta {#{um}shares result
  }>>
    rs = function(expr){
      rsn = random:uuid()
      e = ent:expr // when called in child pico
        || expr    // when called in parent pico
      <<ruleset #{rsn}{
  #{mt}
  global {
    result = function(){
      #{e}
    }
  }
}>>
    }
  }
  rule initialize {
    select when wrangler ruleset_installed
      where event:attr("rids") >< meta:rid
    pre {
      expr = event:attr("expr")
    }
    if expr.isnull() then // in parent pico
      wrangler:createChannel(
        ["console"],
        {"allow":[{"domain":"console","name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"rs"}],"deny":[]}
      )
    notfired { // in child pico
      ent:expr := expr
    }
  }
  rule create_child_picos {
    select when console expr
    pre {
      expr = event:attr("expr")
      name1 = random:uuid()
      name2 = random:uuid()
    }
    if expr then noop()
    fired {
      raise wrangler event "new_child_request" attributes {
        "name": name1
      }
      ent:name1 := name1
      ent:expr := expr
      raise wrangler event "new_child_request" attributes {
        "name": name2
      }
      ent:name2 := name2
    }
  }
  rule initialize_name1 {
    select when wrangler new_child_created
      where event:attr("name") == ent:name1
    pre {
      eci1 = event:attr("eci")
    }
    every {
      event:send({"eci":eci1,
        "domain":"wrangler", "type":"install_ruleset_request",
        "attrs":{"url":meta:rulesetURI,"expr":ent:expr}
      })
      ctx:eventQuery(eci=eci1,
        domain="wrangler", name="new_channel_request",
        attrs={
          "tags":["console"],
          "eventPolicy":{"allow":[],"deny":[{"domain":"*","name":"*"}]},
          "queryPolicy":{"allow":[{"rid":meta:rid,"name":"rs"}],"deny":[]},
        },rid="io.picolabs.wrangler",queryName="channels",
        args={"tags":"console"}
      ) setting(console_channel)
    }
    fired {
      ent:eci1 := eci1
      ent:console_eci := console_channel.head(){"id"}
    }
  }
  rule evaluate_expression {
    select when wrangler new_child_created
      where event:attr("name") == ent:name2
    pre {
      eci1 = ent:console_eci
      url = <<#{meta:host}/sky/cloud/#{eci1}/console/rs.txt>>
      eci2 = event:attr("eci")
    }
    every {
      ctx:eventQuery(eci=eci2,
        domain="wrangler", name="install_ruleset_request",
        attrs={"url":url},
        rid="io.picolabs.wrangler",queryName="installedRIDs",
        args={"tags":"console"}
      ) setting(rids)
      ctx:eventQuery(eci=eci2,
        domain="wrangler", name="new_channel_request",
        attrs={
          "tags":["result"],
          "eventPolicy":{"allow":[],"deny":[{"domain":"*","name":"*"}]},
          "queryPolicy":{"allow":[{"rid":rids[rids.length()-1],"name":"result"}],"deny":[]}
        },rid="io.picolabs.wrangler",queryName="channels",
        args={"tags":"result"}
      ) setting(result_channel)
      http:get(<<#{meta:host}/sky/cloud/#{result_channel.head(){"id"}}/#{rids[rids.length()-1]}/result>>) setting(res)
      send_directive("_txt",{"content":res{"content"}})
    }
    fired {
      raise wrangler event "child_deletion_request" attributes {"eci":ent:eci1}
      raise wrangler event "child_deletion_request" attributes {"eci":eci2}
    }
  }
}
