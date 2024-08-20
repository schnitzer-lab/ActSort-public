% Updates the UI based on the file selection state
function update_enable_state(objects, state)
    for object = objects
        object.Enable = state;
    end
end