"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const intercessionController = __importStar(require("../controllers/intercession.controller"));
const auth_1 = require("../middleware/auth");
const router = (0, express_1.Router)();
// 사용자 검색 (개인 요청 대상자 선택)
router.get('/search-users', auth_1.authenticate, intercessionController.searchUsersForIntercession);
// 중보기도 요청 생성 (전체공개/그룹/개인)
router.post('/', auth_1.authenticate, intercessionController.createIntercessionRequest);
// 받은 중보기도 목록 (나에게 온 요청)
router.get('/received', auth_1.authenticate, intercessionController.getIntercessionRequests);
// 전체공개 중보기도 목록
router.get('/public', auth_1.authenticate, intercessionController.getPublicIntercessionRequests);
// 보낸 중보기도 요청 목록
router.get('/sent', auth_1.authenticate, intercessionController.getSentRequests);
// 요청에 응답 (수락/거절)
router.put('/:requestId/respond', auth_1.authenticate, intercessionController.respondIntercessionRequest);
// 하위 호환 라우트
router.post('/request', auth_1.authenticate, intercessionController.createIntercessionRequest);
router.get('/requests', auth_1.authenticate, intercessionController.getIntercessionRequests);
router.put('/requests/:requestId', auth_1.authenticate, intercessionController.respondIntercessionRequest);
exports.default = router;
//# sourceMappingURL=intercession.routes.js.map