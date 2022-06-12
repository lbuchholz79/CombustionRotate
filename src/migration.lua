-- Runs migrations on the current profile based on the currentMigration value
function CombRotate:migrateProfile()

    if (CombRotate.db.profile.currentMigration == nil) then
        CombRotate.db.profile.currentMigration = 0
    end

    if (CombRotate.db.profile.currentMigration < #CombRotate.migrations) then
        for i = CombRotate.db.profile.currentMigration + 1, #CombRotate.migrations, 1 do
            CombRotate.migrations[i]()
            CombRotate.db.profile.currentMigration = i
        end
    end
end

CombRotate.migrations = {
    -- 1.0.0
    function()
    end,
}
