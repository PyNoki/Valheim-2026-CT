do
maxItemQualityButton.OnClick=function()
  local ok,err=pcall(function()
    assert(not pending,'Another toolkit action is pending. Finish it first.')
    local row=rows[listbox.ItemIndex+1];assert(row,'Select an item first.')
    local current=itemInfo(row.item);local snap=snapshot()
    assert(snap.player==row.player and snap.inventory==row.inventory,'Inventory changed. Refresh first.')
    local found=false;for _,item in ipairs(snap.items) do if item==row.item then found=true;break end end
    assert(found and current.shared==row.shared and current.namePointer==row.namePointer,'Selected item changed. Refresh first.')
    local quality=integer(row.item+offset(current.class,'m_quality'),'item quality')
    local maximum=integer(current.shared+offset(objectClass(current.shared),'m_maxQuality'),'normal quality cap')
    local answer=inputQuery('Set selected item quality','Choose quality 1-1000. Current: '..quality..'; normal maximum: '..maximum..'. Refinement levels can exceed the normal cap.',tostring(quality))
    if answer==nil then return end
    local target=tonumber(answer);assert(target and target==math.floor(target) and target>=1 and target<=1000,'Enter a whole quality level from 1 to 1000.')
    local after=snapshot();assert(after.player==snap.player and after.inventory==snap.inventory and after.collection==snap.collection and after.version==snap.version,'Inventory changed while entering quality. Refresh and retry.')
    if not window then openTeleportWindow();window.hide() end
    local s=context();if hook then stopTeleport() end
    local h=loadRecovery();installHook(s,h)
    invoke(h.quality,0,{{type=vtPointer,value=s.player},{type=vtPointer,value=row.item},{type=vtDword,value=target},{type=vtString,value=s.world}})
    pending={session=s,recovery=h,itemQuality=true};poll.Enabled=true
    status.Caption='Quality change queued. Return to Valheim and unpause.'
  end)
  if not ok then status.Caption=tostring(err) end
end
hint(maxItemQualityButton,'Choose the selected equipment quality, including levels beyond its normal upgrade cap. Changes apply in-game. Existing cheated flags stay unchanged.')
end
