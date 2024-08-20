% Deletes existing patches (cell boundaries) from the map
function delete_existing_patch(axes)
    patch_handle = findobj(axes, 'Type', 'patch', 'Tag', 'Patch');
    if ~isempty(patch_handle)
        delete(patch_handle);
    end
end