-- Additional recipes that are manually maintained
-- These recipes will be merged with auto-generated recipes

-- ASSIGNABLE: Recipes that will have their skill levels assigned by the generation process
local ASSIGNABLE = {
["recipe-oCT00001"]={optional={},cost={copper=5},id="recipe-oCT00001",skill=1,tags={"crafting", "cloth"},outputQty=1,outputItemId="item-r2996",name="Pattern: Bolt of Linen Cloth",profession="Tailoring",reagents={[1]={id="item-r2589",qty=2}},category="Basics",quality="uncommon"},
}

-- HARDCODED: Recipes with fixed skill levels that should never be modified
local HARDCODED = {
["recipe-oCM00001"]={optional={},cost={copper=225},id="recipe-oCM00001",skill=225,tags={"crafting","ingot"},outputQty=1,outputItemId="item-r12359",name="Smelt: Thorium Bar",profession="Mining",reagents={[1]={id="item-r10620",qty=2}},category="Classic Metals",quality="common"},
["recipe-oCM00002"]={optional={},cost={copper=300},id="recipe-oCM00002",skill=300,tags={"crafting","ingot"},outputQty=1,outputItemId="item-r11371",name="Smelt: Dark Iron Bar",profession="Mining",reagents={[1]={id="item-r11370",qty=2}},category="Classic Metals",quality="common"},
["recipe-oCM00003"]={optional={},cost={copper=175},id="recipe-oCM00003",skill=175,tags={"crafting","ingot"},outputQty=1,outputItemId="item-r3860",name="Smelt: Mithril Bar",profession="Mining",reagents={[1]={id="item-r3858",qty=2}},category="Classic Metals",quality="common"},
["recipe-oCM00004"]={optional={},cost={copper=5},id="recipe-oCM00004",skill=1,tags={"crafting","ingot"},outputQty=1,outputItemId="item-r2840",name="Smelt: Copper Bar",profession="Mining",reagents={[1]={id="item-r2770",qty=1}},category="Classic Metals",quality="common"},
["recipe-oCM00005"]={optional={},cost={copper=140},id="recipe-oCM00005",skill=140,tags={"crafting","ingot"},outputQty=1,outputItemId="item-r3859",name="Smelt: Steel Bar",profession="Mining",reagents={[1]={id="item-r2772",qty=2},[2]={id="item-r3857",qty=1}},category="Classic Metals",quality="common"},
["recipe-oCM00006"]={optional={},cost={copper=100},id="recipe-oCM00006",skill=100,tags={"crafting","ingot"},outputQty=1,outputItemId="item-r2842",name="Smelt: Silver Bar",profession="Mining",reagents={[1]={id="item-r2775",qty=1}},category="Classic Metals",quality="common"},
["recipe-oCM00007"]={optional={},cost={copper=110},id="recipe-oCM00007",skill=110,tags={"crafting","ingot"},outputQty=1,outputItemId="item-r3575",name="Smelt: Iron Bar",profession="Mining",reagents={[1]={id="item-r2772",qty=2}},category="Classic Metals",quality="common"},
["recipe-oCM00008"]={optional={},cost={copper=155},id="recipe-oCM00008",skill=155,tags={"crafting","ingot"},outputQty=1,outputItemId="item-r3577",name="Smelt: Gold Bar",profession="Mining",reagents={[1]={id="item-r2776",qty=1}},category="Classic Metals",quality="common"},
["recipe-oCM00009"]={optional={},cost={copper=50},id="recipe-oCM00009",skill=50,tags={"crafting","ingot"},outputQty=1,outputItemId="item-r3576",name="Smelt: Tin Bar",profession="Mining",reagents={[1]={id="item-r2771",qty=1}},category="Classic Metals",quality="common"},
["recipe-oCM00010"]={optional={},cost={copper=75},id="recipe-oCM00010",skill=75,tags={"crafting","ingot"},outputQty=1,outputItemId="item-r2841",name="Smelt: Bronze Bar",profession="Mining",reagents={[1]={id="item-r3576",qty=1}, [2]={id="item-r2840",qty=1}},category="Classic Metals",quality="common"},
["recipe-oCM00011"]={optional={},cost={copper=275},id="recipe-oCM00011",skill=275,tags={"crafting","ingot"},outputQty=1,outputItemId="item-r6037",name="Smelt: Truesilver Bar",profession="Mining",reagents={[1]={id="item-r7911",qty=1}},category="Classic Metals",quality="common"},
}

return { ASSIGNABLE = ASSIGNABLE, HARDCODED = HARDCODED }
