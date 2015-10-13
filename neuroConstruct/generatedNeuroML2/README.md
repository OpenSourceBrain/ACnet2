Some commands which might be useful when viewing cell in OSB 3D Explorer

G.addWidget(6).setData(MediumNet,{layout: 'force', linkType: function(l){return l.getSubNodesOfDomainType('Synapse')[0].id},nodeType: function(n){return n.id.split('_')[0]},linkWeight: function(l){return l.getSubNodesOfDomainType('Synapse')[0].GBase.value}})

G.addWidget(6).setData(MediumNet, {layout: 'chord'})
