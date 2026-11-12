package com.sms.backend.controller;

import static com.sms.backend.repository.Db.*;

import com.sms.backend.security.Actor;
import com.sms.backend.service.finance.InvoiceProposals;
import com.sms.backend.service.resource.Resources;

import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api")
public class ReviewWorkflowController {
    private final Resources resources;
    private final InvoiceProposals proposals;
    private final Actor actor;

    public ReviewWorkflowController(Resources resources, InvoiceProposals proposals, Actor actor) {
        this.resources = resources;
        this.proposals = proposals;
        this.actor = actor;
    }

    @GetMapping("/reviews/{key}")
    Map<String, Object> review(
            @PathVariable String key,
            @RequestParam(defaultValue = "pending") String view,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "") String search) {
        actor.current().require("PRINCIPAL");
        if (!Set.of("pending", "history").contains(view))
            throw error(400, "Chọn danh sách chờ duyệt hoặc lịch sử.");
        return resources.list(key, page, size, search, view);
    }

    @PostMapping("/invoice-proposals")
    Map<String, Object> create(@RequestBody Map<String, Object> input) {
        return map("id", proposals.save(null, input));
    }

    @PutMapping("/invoice-proposals/{id}")
    Map<String, Object> edit(@PathVariable long id, @RequestBody Map<String, Object> input) {
        return map("id", proposals.save(id, input));
    }

    @GetMapping("/invoice-proposals/{id}")
    Map<String, Object> detail(@PathVariable long id) {
        return proposals.detail(id);
    }

    @PostMapping("/invoice-proposals/{id}/{action}")
    void action(
            @PathVariable long id,
            @PathVariable String action,
            @RequestBody Map<String, Object> input) {
        proposals.action(id, action, Objects.toString(input.get("note"), ""));
    }
}
