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
const userController = __importStar(require("../controllers/user.controller"));
const auth_1 = require("../middleware/auth");
const router = (0, express_1.Router)();
router.get('/me', auth_1.authenticate, userController.getMe);
router.put('/me', auth_1.authenticate, userController.updateMe);
router.delete('/me', auth_1.authenticate, userController.deleteMe); // 계정 삭제 (구글 플레이 필수)
router.post('/me/fcm-token', auth_1.authenticate, userController.updateFcmToken); // FCM 토큰 저장/갱신
router.delete('/me/fcm-token', auth_1.authenticate, userController.deleteFcmToken); // FCM 토큰 삭제 (로그아웃 시)
router.get('/search', auth_1.authenticate, userController.searchUsers);
router.get('/me/connections', auth_1.authenticate, userController.getConnections);
router.post('/me/connections', auth_1.authenticate, userController.addConnection);
router.get('/:userId', userController.getUserById);
router.get('/:userId/stats', userController.getUserStats);
exports.default = router;
//# sourceMappingURL=user.routes.js.map