// نظام المزامنة بدون اتصال
const offlineSync = {
    pendingOperations: [],
    
    // دالة لتحميل العمليات من localStorage عند البدء
    loadPending() {
        const stored = localStorage.getItem('pendingOperations');
        if (stored) {
            try {
                this.pendingOperations = JSON.parse(stored);
                console.log(`تم تحميل ${this.pendingOperations.length} عملية معلقة`);
            } catch(e) {
                console.error('خطأ في تحميل العمليات المحفوظة', e);
                this.pendingOperations = [];
            }
        } else {
            this.pendingOperations = [];
        }
    },
    
    async saveOperation(url, method, data) {
        const op = {
            id: Date.now() + '-' + Math.random(),
            url: url,
            method: method,
            data: data,
            timestamp: new Date().toISOString()
        };
        this.pendingOperations.push(op);
        localStorage.setItem('pendingOperations', JSON.stringify(this.pendingOperations));
        console.log('تم حفظ العملية للمزامنة لاحقاً');
        return op.id;
    },
    
    async syncPending() {
        if (!navigator.onLine) return false;
        const pending = JSON.parse(localStorage.getItem('pendingOperations') || '[]');
        if (pending.length === 0) return true;
        
        try {
            const response = await fetch('/api/sync-pending', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ operations: pending })
            });
            const result = await response.json();
            if (result.success) {
                const failed = result.results.filter(r => !r.success).map(r => r.id);
                const newPending = pending.filter(op => failed.includes(op.id));
                localStorage.setItem('pendingOperations', JSON.stringify(newPending));
                this.pendingOperations = newPending;
                console.log('تمت مزامنة العمليات بنجاح');
                if (failed.length > 0) {
                    console.warn(`فشلت مزامنة ${failed.length} عملية`);
                }
            }
            return result.success;
        } catch (e) {
            console.error('فشل المزامنة:', e);
            return false;
        }
    }
};

// تحميل العمليات عند بدء التشغيل
offlineSync.loadPending();

window.offlineSync = offlineSync;

window.addEventListener('online', () => offlineSync.syncPending());

setInterval(() => {
    if (navigator.onLine) offlineSync.syncPending();
}, 30000);

export default offlineSync;