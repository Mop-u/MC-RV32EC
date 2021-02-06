interface tag_pool_if #(
    parameter tag_w = 4
)();
tag_pool_issue_if #(.tag_w(tag_w)) Issue();
tag_pool_retire_if #(.tag_w(tag_w)) Retire();
endinterface

interface tag_pool_issue_if #(
    parameter tag_w = 4
)();
logic Tag;
logic Enable;
logic Available;
endinterface

interface tag_pool_retire_if #(
    parameter tag_w = 4
)();
logic Tag;
logic Enable;
endinterface
